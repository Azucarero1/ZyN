import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Capa decorativa de fondo con pétalos cayendo en bucle infinito.
///
/// Cada pétalo es un objeto [_Petalo] con su propia velocidad, deriva
/// horizontal, rotación y tamaño. La animación es implícita (un único
/// `Ticker` global) y los pétalos se reciclan automáticamente cuando
/// salen por la parte inferior.
///
/// Diseñado para colocarse como capa entre el fondo y el contenido
/// con `IgnorePointer` para que no intercepte gestos del usuario.
class PetalosAnimados extends StatefulWidget {
  /// Número de pétalos simultáneos en pantalla.
  final int densidad;

  /// Si es false, los pétalos no se mueven (útil para reducir batería
  /// cuando otra animación intensiva está activa).
  final bool activo;

  const PetalosAnimados({
    super.key,
    this.densidad = 18,
    this.activo = true,
  });

  @override
  State<PetalosAnimados> createState() => _PetalosAnimadosState();
}

class _PetalosAnimadosState extends State<PetalosAnimados>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Petalo> _petalos;
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Periodo arbitrario; lo que importa es que avance constantemente.
      duration: const Duration(seconds: 30),
    );
    _petalos = List.generate(widget.densidad, (i) => _generarPetalo(true));
    if (widget.activo) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PetalosAnimados old) {
    super.didUpdateWidget(old);
    if (widget.activo != old.activo) {
      if (widget.activo) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.densidad != old.densidad) {
      // Ajusta el array al nuevo tamaño manteniendo los existentes.
      if (widget.densidad > _petalos.length) {
        _petalos.addAll(List.generate(
          widget.densidad - _petalos.length,
          (_) => _generarPetalo(true),
        ));
      } else {
        _petalos.removeRange(widget.densidad, _petalos.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Genera un pétalo aleatorio. Si [iniciandoEscena] es true, lo coloca
  /// en cualquier parte del recorrido (para que el primer frame tenga
  /// pétalos repartidos). Si no, lo coloca encima de la pantalla.
  _Petalo _generarPetalo(bool iniciandoEscena) {
    final yInicial = iniciandoEscena ? _rng.nextDouble() : -_rng.nextDouble() * 0.3;
    return _Petalo(
      xInicial: _rng.nextDouble(),
      yInicial: yInicial,
      // Cada pétalo cae a su propio ritmo: 18-32 segundos.
      velocidad: 0.55 + _rng.nextDouble() * 0.45,
      // Amplitud del balanceo horizontal.
      amplitudX: 0.04 + _rng.nextDouble() * 0.08,
      // Frecuencia del balanceo.
      frecuenciaX: 0.6 + _rng.nextDouble() * 0.8,
      // Rotación inicial y velocidad de giro.
      rotacionInicial: _rng.nextDouble() * 2 * pi,
      velocidadRotacion: (_rng.nextDouble() - 0.5) * 1.2,
      tamano: 8.0 + _rng.nextDouble() * 14.0,
      opacidad: 0.18 + _rng.nextDouble() * 0.32,
      tono: _rng.nextDouble() < 0.6 ? _Tono.granate : _Tono.oro,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _PainterPetalos(
                petalos: _petalos,
                tiempoGlobal: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

enum _Tono { granate, oro }

class _Petalo {
  final double xInicial;       // 0..1, posición horizontal base
  final double yInicial;       // 0..1, posición vertical inicial
  final double velocidad;      // 0..1, qué tan rápido cae
  final double amplitudX;      // 0..0.12, balanceo lateral
  final double frecuenciaX;    // 0..1.4, frecuencia del balanceo
  final double rotacionInicial; // 0..2π
  final double velocidadRotacion; // -0.6..0.6
  final double tamano;          // 8..22 px
  final double opacidad;        // 0.18..0.5
  final _Tono tono;

  _Petalo({
    required this.xInicial,
    required this.yInicial,
    required this.velocidad,
    required this.amplitudX,
    required this.frecuenciaX,
    required this.rotacionInicial,
    required this.velocidadRotacion,
    required this.tamano,
    required this.opacidad,
    required this.tono,
  });
}

class _PainterPetalos extends CustomPainter {
  final List<_Petalo> petalos;
  final double tiempoGlobal;

  _PainterPetalos({
    required this.petalos,
    required this.tiempoGlobal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petalos) {
      // Posición Y: avanza linealmente con el tiempo y la velocidad propia
      // y se cicla con módulo (cada pétalo reaparece arriba al salir abajo).
      final progresoY = (p.yInicial + tiempoGlobal * p.velocidad) % 1.0;
      // Posición X: oscila como una hoja real al caer.
      final xOscilacion = sin(tiempoGlobal * 2 * pi * p.frecuenciaX +
              p.rotacionInicial) *
          p.amplitudX;
      final px = (p.xInicial + xOscilacion).clamp(-0.05, 1.05) * size.width;
      final py = progresoY * (size.height + 80) - 40;

      _dibujarPetalo(canvas, p, Offset(px, py));
    }
  }

  void _dibujarPetalo(Canvas canvas, _Petalo p, Offset centro) {
    final color = (p.tono == _Tono.granate ? AppColors.granate : AppColors.oro);
    final paint = Paint()
      ..color = color.withValues(alpha: p.opacidad)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    final rotacion = p.rotacionInicial + tiempoGlobal * 2 * pi * p.velocidadRotacion;

    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(rotacion);

    // Forma del pétalo: óvalo asimétrico tipo "lágrima".
    final ancho = p.tamano * 0.55;
    final alto = p.tamano;
    final path = Path()
      ..moveTo(0, -alto / 2)
      ..quadraticBezierTo(ancho, -alto / 4, ancho * 0.6, alto / 2)
      ..quadraticBezierTo(0, alto / 2 + 2, -ancho * 0.6, alto / 2)
      ..quadraticBezierTo(-ancho, -alto / 4, 0, -alto / 2)
      ..close();
    canvas.drawPath(path, paint);

    // Veta interior tenue (refleja luz como si fuera un pétalo real).
    final paintVeta = Paint()
      ..color = Colors.white.withValues(alpha: p.opacidad * 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, -alto / 2 + 2),
      Offset(0, alto / 2 - 2),
      paintVeta,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PainterPetalos old) =>
      old.tiempoGlobal != tiempoGlobal;
}
