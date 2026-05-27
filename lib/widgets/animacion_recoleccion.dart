import 'dart:math';

import 'package:flutter/material.dart';

/// Animación de recolección: una flor de jazmín vuela desde la posición
/// del jazmín principal (centro de la pantalla, sobre la maceta) hasta
/// el panel lateral derecho donde está el ramo, dejando un rastro de
/// pequeños pétalos que se desvanecen.
///
/// Al terminar invoca [onCompleta] para que el estado avance:
/// `EstadoJardin.recolectarFlor()` y se oculte este overlay.
///
/// Diseño:
///  · Trayectoria: curva Bezier cuadrática (arco hacia arriba-derecha).
///  · Duración: 1.8 s con `Curves.easeInOutCubic`.
///  · Escala: 1.0 → 0.40 conforme se acerca al ramo (perspectiva).
///  · Rotación: 2 giros completos durante el vuelo.
///  · Trail: 8 pétalos que rastrean la posición histórica de la flor.
class AnimacionRecoleccion extends StatefulWidget {
  /// Se llama cuando la animación termina por completo.
  final VoidCallback onCompleta;

  const AnimacionRecoleccion({super.key, required this.onCompleta});

  @override
  State<AnimacionRecoleccion> createState() => _AnimacionRecoleccionState();
}

class _AnimacionRecoleccionState extends State<AnimacionRecoleccion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _yaTermino = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
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

          // Puntos de la curva en coordenadas de pantalla.
          final inicio = Offset(w * 0.50, h * 0.40);    // sobre la maceta
          final control = Offset(w * 0.75, h * 0.15);   // arco arriba-derecha
          final destino = Offset(w * 0.92, h * 0.45);   // panel derecho

          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final tRaw = _controller.value.clamp(0.0, 1.0);
              final t = Curves.easeInOutCubic.transform(tRaw);

              final pos = _bezierCuadratica(inicio, control, destino, t);
              final escala = (1.0 - t * 0.60).clamp(0.0, 1.0);
              final rotacion = t * 4 * pi;
              // Opacidad de la flor: visible casi todo el viaje, fade al final.
              // Clamp por si el controller queda en un valor fuera de rango
              // durante la transición final (evita assertion del Opacity).
              final opacidadRaw =
                  tRaw < 0.85 ? 1.0 : (1.0 - (tRaw - 0.85) / 0.15);
              final opacidad = opacidadRaw.clamp(0.0, 1.0);

              return Stack(
                children: [
                  // Trail de pétalos (rastros históricos).
                  ..._construirTrail(t, inicio, control, destino),

                  // Flor principal.
                  Positioned(
                    left: pos.dx - 28,
                    top: pos.dy - 28,
                    child: Opacity(
                      opacity: opacidad,
                      child: Transform.scale(
                        scale: escala,
                        child: Transform.rotate(
                          angle: rotacion,
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: CustomPaint(
                              painter: _FlorJazminVolando(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Pequeños pétalos a lo largo de la trayectoria, con opacidad
  /// decreciente cuanto más atrás están del punto actual.
  List<Widget> _construirTrail(
    double t,
    Offset inicio,
    Offset control,
    Offset destino,
  ) {
    const cantidad = 8;
    final widgets = <Widget>[];

    for (var i = 1; i <= cantidad; i++) {
      final dt = i * 0.045;
      final tTrail = t - dt;
      if (tTrail < 0) continue;

      final pos = _bezierCuadratica(inicio, control, destino, tTrail);
      final opacidad = ((1.0 - i / cantidad) * 0.55).clamp(0.0, 1.0);
      final radio = (4.0 - i * 0.25).clamp(0.5, double.infinity);

      widgets.add(Positioned(
        left: pos.dx - radio,
        top: pos.dy - radio,
        child: Opacity(
          opacity: opacidad,
          child: Container(
            width: radio * 2,
            height: radio * 2,
            decoration: BoxDecoration(
              color: const Color(0xFFFCF6E6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFE0B0).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ));
    }

    return widgets;
  }

  /// Punto sobre una curva Bezier cuadrática para `t ∈ [0, 1]`.
  Offset _bezierCuadratica(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
      mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy,
    );
  }
}

/// Flor de jazmín en estilo cartoon con contorno — la misma estética
/// que usa `RamoPainter` para que la animación encaje visualmente.
class _FlorJazminVolando extends CustomPainter {
  const _FlorJazminVolando();

  static const Color _contorno = Color(0xFF2A1810);
  static const Color _petalo = Color(0xFFFCF6E6);
  static const Color _centro = Color(0xFFF0B848);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final tamano = size.width * 0.9;

    canvas.save();
    canvas.translate(cx, cy);

    final radioPetalo = tamano * 0.32;
    final separacion = tamano * 0.30;

    final fill = Paint()..color = _petalo;
    final outline = Paint()
      ..color = _contorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;

    // Sombra suave debajo.
    canvas.drawCircle(
      const Offset(2, 3),
      tamano * 0.42,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 5 pétalos (relleno primero).
    for (var i = 0; i < 5; i++) {
      final ang = (i * 2 * pi / 5) - pi / 2;
      final px = cos(ang) * separacion;
      final py = sin(ang) * separacion;
      canvas.drawCircle(Offset(px, py), radioPetalo, fill);
    }
    // Contornos.
    for (var i = 0; i < 5; i++) {
      final ang = (i * 2 * pi / 5) - pi / 2;
      final px = cos(ang) * separacion;
      final py = sin(ang) * separacion;
      canvas.drawCircle(Offset(px, py), radioPetalo, outline);
    }

    // Centro amarillo con contorno.
    canvas.drawCircle(Offset.zero, tamano * 0.18, Paint()..color = _centro);
    canvas.drawCircle(Offset.zero, tamano * 0.18, outline);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlorJazminVolando old) => false;
}
