import 'dart:math';

import 'package:flutter/material.dart';

/// Capa decorativa de luciérnagas parpadeando — solo se usa de noche.
///
/// Cada luciérnaga es un puntito amarillo-verdoso que pulsa con su propio
/// ritmo y se desplaza muy lentamente. Tienen un halo difuso que sugiere
/// el resplandor del bicho. Se distribuyen evitando una **zona central
/// excluida** (un rectángulo que cubre la maceta y la planta) para no
/// quedar encima del jazmín.
///
/// Diseñado para colocarse como capa entre el fondo y el contenido con
/// `IgnorePointer`, igual que [PetalosAnimados].
class LuciernagasAnimadas extends StatefulWidget {
  /// Número de luciérnagas en pantalla.
  final int densidad;

  /// Si es false, las luciérnagas no se animan.
  final bool activo;

  /// Rectángulo de exclusión en coordenadas relativas (0..1) donde NO
  /// se permitirá que aparezcan luciérnagas. Por defecto, una franja
  /// central vertical que cubre la zona de la maceta y la planta.
  final Rect zonaExcluida;

  const LuciernagasAnimadas({
    super.key,
    this.densidad = 22,
    this.activo = true,
    this.zonaExcluida = const Rect.fromLTRB(0.30, 0.20, 0.70, 0.85),
  });

  @override
  State<LuciernagasAnimadas> createState() => _LuciernagasAnimadasState();
}

class _LuciernagasAnimadasState extends State<LuciernagasAnimadas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Luciernaga> _luciernagas;
  final Random _rng = Random(13);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _luciernagas = List.generate(widget.densidad, (_) => _generar());
    if (widget.activo) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant LuciernagasAnimadas old) {
    super.didUpdateWidget(old);
    if (widget.activo != old.activo) {
      if (widget.activo) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.densidad != old.densidad) {
      if (widget.densidad > _luciernagas.length) {
        _luciernagas.addAll(List.generate(
          widget.densidad - _luciernagas.length,
          (_) => _generar(),
        ));
      } else {
        _luciernagas.removeRange(widget.densidad, _luciernagas.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Genera una luciérnaga con posición aleatoria pero FUERA de la zona
  /// excluida. Si el primer intento cae dentro, repite hasta encontrar
  /// una posición válida (máx 8 intentos).
  _Luciernaga _generar() {
    double x = 0, y = 0;
    for (var i = 0; i < 8; i++) {
      x = _rng.nextDouble();
      y = _rng.nextDouble() * 0.92; // no en el extremo inferior
      if (!widget.zonaExcluida.contains(Offset(x, y))) break;
      // Si seguimos dentro, empújala al lado más cercano fuera del rect.
      if (i == 7) {
        if (x < 0.5) {
          x = widget.zonaExcluida.left * _rng.nextDouble();
        } else {
          x = widget.zonaExcluida.right +
              (1.0 - widget.zonaExcluida.right) * _rng.nextDouble();
        }
      }
    }

    return _Luciernaga(
      xInicial: x,
      yInicial: y,
      // Cada luciérnaga parpadea a su propio ritmo (0.4–1.4 ciclos/s).
      frecuenciaParpadeo: 0.4 + _rng.nextDouble() * 1.0,
      faseParpadeo: _rng.nextDouble() * 2 * pi,
      // Frecuencias del leve flotar (drift).
      frecuenciaDriftX: 0.15 + _rng.nextDouble() * 0.30,
      frecuenciaDriftY: 0.10 + _rng.nextDouble() * 0.25,
      // Tamaño del puntito y del halo.
      tamano: 1.4 + _rng.nextDouble() * 1.6,
      tamanoHalo: 8.0 + _rng.nextDouble() * 14.0,
      brilloMax: 0.65 + _rng.nextDouble() * 0.35,
      // Color: verde-amarillo de luciérnaga real.
      tono: _rng.nextDouble() < 0.7 ? _Tono.verdoso : _Tono.amarillento,
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
              painter: _PainterLuciernagas(
                luciernagas: _luciernagas,
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

enum _Tono { verdoso, amarillento }

class _Luciernaga {
  final double xInicial;          // 0..1, posición horizontal base
  final double yInicial;          // 0..1, posición vertical base
  final double frecuenciaParpadeo; // ciclos por unidad de tiempo
  final double faseParpadeo;       // 0..2π
  final double frecuenciaDriftX;
  final double frecuenciaDriftY;
  final double tamano;             // 1.4..3 px (puntito interior)
  final double tamanoHalo;         // 8..22 px (halo difuso)
  final double brilloMax;          // 0.65..1.0
  final _Tono tono;

  const _Luciernaga({
    required this.xInicial,
    required this.yInicial,
    required this.frecuenciaParpadeo,
    required this.faseParpadeo,
    required this.frecuenciaDriftX,
    required this.frecuenciaDriftY,
    required this.tamano,
    required this.tamanoHalo,
    required this.brilloMax,
    required this.tono,
  });
}

class _PainterLuciernagas extends CustomPainter {
  final List<_Luciernaga> luciernagas;
  final double tiempoGlobal;

  _PainterLuciernagas({
    required this.luciernagas,
    required this.tiempoGlobal,
  });

  // Colores de las luciérnagas.
  static const Color _coreVerde = Color(0xFFD4FF80);
  static const Color _haloVerde = Color(0xFFA8E040);
  static const Color _coreAmarillo = Color(0xFFFFE890);
  static const Color _haloAmarillo = Color(0xFFE8B040);

  @override
  void paint(Canvas canvas, Size size) {
    final t = tiempoGlobal * 2 * pi;
    for (final l in luciernagas) {
      // Drift suave para que floten ligeramente.
      final dx = sin(t * l.frecuenciaDriftX + l.faseParpadeo) * 0.012;
      final dy = cos(t * l.frecuenciaDriftY + l.faseParpadeo) * 0.010;
      final px = (l.xInicial + dx).clamp(0.01, 0.99) * size.width;
      final py = (l.yInicial + dy).clamp(0.01, 0.95) * size.height;

      // Parpadeo: usamos sin² para tener picos suaves separados por
      // periodos de "apagado".
      final s = sin(t * l.frecuenciaParpadeo + l.faseParpadeo);
      // Eleva al cuadrado para acentuar los picos y aplanar los valles.
      final brillo = (s * s) * l.brilloMax;
      if (brillo < 0.04) continue; // ahorra dibujo cuando está casi apagada

      final core = l.tono == _Tono.verdoso ? _coreVerde : _coreAmarillo;
      final halo = l.tono == _Tono.verdoso ? _haloVerde : _haloAmarillo;

      // Halo difuso (capa más amplia).
      canvas.drawCircle(
        Offset(px, py),
        l.tamanoHalo,
        Paint()
          ..color = halo.withValues(alpha: brillo * 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      // Halo intermedio.
      canvas.drawCircle(
        Offset(px, py),
        l.tamanoHalo * 0.45,
        Paint()
          ..color = halo.withValues(alpha: brillo * 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Núcleo brillante.
      canvas.drawCircle(
        Offset(px, py),
        l.tamano,
        Paint()..color = core.withValues(alpha: brillo),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PainterLuciernagas old) =>
      old.tiempoGlobal != tiempoGlobal;
}
