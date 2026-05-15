import 'dart:math';

import 'package:flutter/material.dart';

/// Animación de riego: cae una lluvia de gotas azules desde arriba sobre
/// la zona de la maceta. Cada gota tiene su propio delay y duración para
/// que el efecto se vea como una micro-tormenta cariñosa, no como
/// una caída sincrónica.
///
/// Al terminar invoca [onCompleta] para que el estado avance:
/// `EstadoJardin.regarPlanta()` y se oculte este overlay.
///
/// Diseño:
///  · Zona de caída: franja vertical centrada (~30 % del ancho), justo
///    encima de la maceta (entre y=15 % y y=50 %).
///  · Duración total: 1.4 s, con 14 gotas y delays escalonados.
///  · Caída acelerada (gravedad simulada: y ∝ t²).
///  · Cada gota tiene un splash final (círculo expansivo) al impactar.
class AnimacionRiego extends StatefulWidget {
  /// Se llama cuando la animación termina por completo.
  final VoidCallback onCompleta;

  const AnimacionRiego({super.key, required this.onCompleta});

  @override
  State<AnimacionRiego> createState() => _AnimacionRiegoState();
}

class _AnimacionRiegoState extends State<AnimacionRiego>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Gota> _gotas;
  bool _yaTermino = false;

  static const int _numGotas = 14;
  static const Duration _duracion = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duracion);

    final rng = Random(11);
    _gotas = List.generate(_numGotas, (i) {
      // Distribución horizontal con leve aleatoriedad, dentro de la zona
      // central donde está la maceta.
      final xNorm = (i / (_numGotas - 1)); // 0..1 lineal por la franja
      final xJitter = (rng.nextDouble() - 0.5) * 0.08;
      return _Gota(
        xRel: 0.35 + (xNorm * 0.30) + xJitter, // 0.35..0.65 del ancho
        delay: i * 0.045 + rng.nextDouble() * 0.05,
        duracionCaida: 0.35 + rng.nextDouble() * 0.20,
        tamano: 4.0 + rng.nextDouble() * 2.5,
      );
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_yaTermino) {
        _yaTermino = true;
        widget.onCompleta();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Y inicial (sobre la maceta) y Y final (a la altura de la tierra).
          final yInicio = h * 0.18;
          final yFinal = h * 0.52;

          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = _controller.value;
              final widgets = <Widget>[];

              for (final g in _gotas) {
                final tLocal = ((t - g.delay) / g.duracionCaida).clamp(0.0, 1.2);
                if (tLocal <= 0) continue;

                if (tLocal < 1.0) {
                  // ━━━ Gota cayendo (acelerada con t²) ━━━
                  final y = yInicio + (yFinal - yInicio) * (tLocal * tLocal);
                  final x = g.xRel * w;
                  widgets.add(Positioned(
                    left: x - g.tamano / 2,
                    top: y - g.tamano,
                    child: Container(
                      width: g.tamano,
                      height: g.tamano * 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x80B0DCF0),
                            Color(0xFF6FB8E0),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(g.tamano * 0.4),
                          topRight: Radius.circular(g.tamano * 0.4),
                          bottomLeft: Radius.circular(g.tamano),
                          bottomRight: Radius.circular(g.tamano),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8FCFEC)
                                .withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ));
                } else {
                  // ━━━ Splash: la gota acaba de impactar ━━━
                  final tSplash = (tLocal - 1.0).clamp(0.0, 0.2) / 0.2;
                  final radio = g.tamano * (1 + tSplash * 3);
                  final opacidad = (1.0 - tSplash) * 0.7;
                  widgets.add(Positioned(
                    left: g.xRel * w - radio,
                    top: yFinal - radio * 0.3,
                    child: Container(
                      width: radio * 2,
                      height: radio * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(radio),
                        border: Border.all(
                          color: const Color(0xFF8FCFEC)
                              .withValues(alpha: opacidad),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ));
                }
              }

              return Stack(children: widgets);
            },
          );
        },
      ),
    );
  }
}

class _Gota {
  /// Posición horizontal relativa al ancho del canvas (0..1).
  final double xRel;

  /// Delay antes de que esta gota empiece a caer (0..1 del controller).
  final double delay;

  /// Duración de la caída de esta gota (0..1 del controller).
  final double duracionCaida;

  /// Tamaño base de la gota en píxeles.
  final double tamano;

  const _Gota({
    required this.xRel,
    required this.delay,
    required this.duracionCaida,
    required this.tamano,
  });
}
