import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'fondo_jardin.dart';

/// Pinta una maceta de terracota vintage **realista** que se apoya en la
/// mesa que aparece en la imagen de fondo del jardín.
///
/// Diseño:
///  - El cuerpo ocupa la mitad inferior del canvas (la mitad superior
///    queda libre para que el jazmín crezca). El plant grows above; the
///    pot's bottom touches the canvas bottom (= table top in the BG image).
///  - Cuerpo trapezoidal levemente curvado, rim rectangular grueso.
///  - **Capa de envejecimiento**: manchas tonales suaves, salpicaduras de
///    sales/cal (drip stains), motas oscuras y claras, hairline scratches,
///    un toquecito verde (musgo) en la base. Todo recortado al cuerpo.
///  - Sombra de contacto fuerte que cae sobre la mesa de fondo.
class MacetaPainter extends CustomPainter {
  const MacetaPainter();

  // Paleta de terracota vintage.
  static const Color _terracotaClaro = Color(0xFFC78656);
  static const Color _terracotaMedio = Color(0xFFA56640);
  static const Color _terracotaOscuro = Color(0xFF6B3F25);
  static const Color _terracotaSombra = Color(0xFF4A2A18);
  static const Color _interiorMaceta = Color(0xFF2A150A);
  static const Color _tierraHumeda = Color(0xFF3A1F10);
  static const Color _tierraOscura = Color(0xFF1A0D06);
  // Tonos de envejecimiento.
  static const Color _calClara = Color(0xFFE6D2B0);
  static const Color _musgo = Color(0xFF4A5028);
  static const Color _musgoOscuro = Color(0xFF38421C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // La maceta ocupa la MITAD INFERIOR del canvas; la imagen de fondo
    // se encarga de la mesa donde reposa.
    //   y ∈ [0.00, 0.55]  → libre para el jazmín que crece hacia arriba
    //   y ∈ [0.55, 0.96]  → la maceta (rim + cuerpo)
    //   y ∈ [0.96, 1.00]  → sombra de contacto sobre la mesa del fondo
    final bordeAlto = h * 0.035;          // rim grueso visible
    final macetaTop = h * 0.555;          // top del rim
    final macetaBottom = h * 0.94;        // base del cuerpo (toca la mesa)
    final bordeIzq = w * 0.08;
    final bordeDer = w * 0.92;
    final cuerpoArribaIzq = w * 0.13;
    final cuerpoArribaDer = w * 0.87;
    final cuerpoAbajoIzq = w * 0.22;      // estrechamiento moderado
    final cuerpoAbajoDer = w * 0.78;

    // ───── 1. SOMBRAS DE CONTACTO ─────
    // Sombra ambiental amplia (más difusa, más lejana del pot).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, macetaBottom + 8),
        width: w * 0.74,
        height: 18,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    // Sombra de contacto (más oscura, justo bajo la base).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, macetaBottom + 3),
        width: w * 0.55,
        height: 10,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ───── 2. CUERPO TRAPEZOIDAL ─────
    final cuerpoTop = macetaTop + bordeAlto;
    final cuerpoPath = Path()
      ..moveTo(cuerpoArribaIzq, cuerpoTop)
      ..lineTo(cuerpoAbajoIzq, macetaBottom - 3)
      ..quadraticBezierTo(
        w * 0.5, macetaBottom + 3, cuerpoAbajoDer, macetaBottom - 3)
      ..lineTo(cuerpoArribaDer, cuerpoTop)
      ..close();

    final cuerpoRect = Rect.fromLTRB(
      cuerpoArribaIzq, cuerpoTop, cuerpoArribaDer, macetaBottom);
    canvas.drawPath(
      cuerpoPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _terracotaClaro,
            _terracotaMedio,
            _terracotaOscuro,
            _terracotaSombra,
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
        ).createShader(cuerpoRect),
    );

    // ───── 3. CAPA DE ENVEJECIMIENTO (recortada al cuerpo) ─────
    canvas.save();
    canvas.clipPath(cuerpoPath);
    _aplicarEnvejecimiento(
        canvas, w, cuerpoTop, macetaBottom, cuerpoArribaIzq, cuerpoArribaDer);
    canvas.restore();

    // ───── 4. HIGHLIGHT izquierdo (luz cayendo desde arriba-izq) ─────
    final highlightPath = Path()
      ..moveTo(cuerpoArribaIzq + 2, cuerpoTop + 1)
      ..lineTo(cuerpoAbajoIzq + 4, macetaBottom - 8)
      ..lineTo(cuerpoAbajoIzq + 12, macetaBottom - 8)
      ..lineTo(cuerpoArribaIzq + 16, cuerpoTop + 1)
      ..close();
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // ───── 5. SOMBRA interior derecha (volumen 3D) ─────
    final sombraDerPath = Path()
      ..moveTo(cuerpoArribaDer - 16, cuerpoTop + 1)
      ..lineTo(cuerpoAbajoDer - 12, macetaBottom - 8)
      ..lineTo(cuerpoAbajoDer - 4, macetaBottom - 8)
      ..lineTo(cuerpoArribaDer - 2, cuerpoTop + 1)
      ..close();
    canvas.drawPath(
      sombraDerPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // ───── 6. INICIAL "Z" grabada — detalle vintage ─────
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Z',
        style: TextStyle(
          color: Color(0x555A2810),
          fontSize: 30,
          fontFamily: 'GreatVibes',
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(w * 0.5 - tp.width / 2,
          macetaTop + (macetaBottom - macetaTop) * 0.55),
    );

    // ───── 7. RIM — rectángulo limpio sobresaliendo del cuerpo ─────
    final bordeRect = Rect.fromLTRB(
        bordeIzq, macetaTop, bordeDer, macetaTop + bordeAlto);
    canvas.drawRect(
      bordeRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD9986A),
            _terracotaClaro,
            _terracotaMedio,
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(bordeRect),
    );

    // Línea oscura bajo el rim (separación del cuerpo).
    canvas.drawLine(
      Offset(bordeIzq, macetaTop + bordeAlto - 0.5),
      Offset(bordeDer, macetaTop + bordeAlto - 0.5),
      Paint()
        ..color = _terracotaSombra.withValues(alpha: 0.75)
        ..strokeWidth = 1.5,
    );

    // Cantos verticales del rim.
    canvas.drawLine(
      Offset(bordeIzq + 0.5, macetaTop + 1),
      Offset(bordeIzq + 0.5, macetaTop + bordeAlto - 1),
      Paint()
        ..color = _terracotaSombra.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(bordeDer - 0.5, macetaTop + 1),
      Offset(bordeDer - 0.5, macetaTop + bordeAlto - 1),
      Paint()
        ..color = _terracotaSombra.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Marca pequeña de desconchón en el rim (detalle realista).
    canvas.drawArc(
      Rect.fromLTWH(
          bordeIzq + (bordeDer - bordeIzq) * 0.18, macetaTop - 1, 6, 4),
      0,
      pi,
      false,
      Paint()
        ..color = _terracotaSombra.withValues(alpha: 0.6),
    );

    // ───── 8. INTERIOR de la maceta (elipse oscura, profundidad) ─────
    final aperturaIzq = bordeIzq + 9;
    final aperturaDer = bordeDer - 9;
    final aperturaCentroY = macetaTop + bordeAlto * 0.45;
    final aperturaAlto = bordeAlto * 0.85;

    final interiorRect = Rect.fromLTRB(
      aperturaIzq,
      aperturaCentroY - aperturaAlto / 2,
      aperturaDer,
      aperturaCentroY + aperturaAlto / 2,
    );
    canvas.drawOval(
      interiorRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          colors: [_tierraHumeda, _interiorMaceta, _tierraOscura],
          stops: [0.0, 0.7, 1.0],
        ).createShader(interiorRect),
    );
    canvas.drawOval(
      interiorRect,
      Paint()
        ..color = const Color(0xFF1A0805).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ───── 9. TIERRA dentro de la apertura ─────
    final tierraRect = Rect.fromCenter(
      center: Offset(w * 0.5, aperturaCentroY + aperturaAlto * 0.05),
      width: (aperturaDer - aperturaIzq) * 0.85,
      height: aperturaAlto * 0.65,
    );
    canvas.drawOval(
      tierraRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.1, -0.4),
          colors: [Color(0xFF5A3520), _tierraHumeda, _tierraOscura],
          stops: [0.0, 0.55, 1.0],
        ).createShader(tierraRect),
    );

    // Motas de tierra dentro de la elipse de tierra.
    final rng = Random(42);
    for (var i = 0; i < 16; i++) {
      final dx =
          tierraRect.left + 3 + rng.nextDouble() * (tierraRect.width - 6);
      final dy =
          tierraRect.top + 2 + rng.nextDouble() * (tierraRect.height - 4);
      final centroEx = tierraRect.center;
      final dxNorm = (dx - centroEx.dx) / (tierraRect.width / 2);
      final dyNorm = (dy - centroEx.dy) / (tierraRect.height / 2);
      if (dxNorm * dxNorm + dyNorm * dyNorm > 0.85) continue;
      canvas.drawCircle(
        Offset(dx, dy),
        0.5 + rng.nextDouble() * 1.2,
        Paint()
          ..color = const Color(0xFF0F0805).withValues(
            alpha: 0.45 + rng.nextDouble() * 0.4,
          ),
      );
    }
  }

  /// Aplica todas las capas de envejecimiento sobre el cuerpo de la maceta:
  /// manchas tonales, salpicaduras de cal/agua, motas, rayones y musgo.
  /// Llamar SIEMPRE dentro de un `clipPath(cuerpoPath)` para no desbordar.
  void _aplicarEnvejecimiento(
    Canvas canvas,
    double w,
    double cuerpoTop,
    double macetaBottom,
    double cuerpoArribaIzq,
    double cuerpoArribaDer,
  ) {
    final bodyHeight = macetaBottom - cuerpoTop;
    final rng = Random(73);

    // 1. Manchas tonales suaves (variaciones de color del barro).
    for (var i = 0; i < 7; i++) {
      final cx = w * 0.13 + rng.nextDouble() * w * 0.74;
      final cy = cuerpoTop + 4 + rng.nextDouble() * (bodyHeight - 8);
      final radio = 14.0 + rng.nextDouble() * 18;
      final masOscuro = rng.nextBool();
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: radio * 2,
          height: radio * 1.3,
        ),
        Paint()
          ..color = (masOscuro
                  ? _terracotaSombra
                  : const Color(0xFFD9986A))
              .withValues(alpha: 0.16 + rng.nextDouble() * 0.10)
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, 8 + rng.nextDouble() * 7),
      );
    }

    // 2. Drip stains: regueros verticales de cal por riego.
    for (var i = 0; i < 3; i++) {
      final xStart = w * 0.20 + rng.nextDouble() * w * 0.60;
      final yStart = cuerpoTop + 1;
      final yEnd = cuerpoTop + bodyHeight * (0.35 + rng.nextDouble() * 0.45);
      final ancho = 1.2 + rng.nextDouble() * 1.6;

      final dripPath = Path()
        ..moveTo(xStart - ancho, yStart)
        ..quadraticBezierTo(
          xStart - ancho * 0.4 + (rng.nextDouble() - 0.5) * 4,
          (yStart + yEnd) * 0.5,
          xStart - ancho * 0.5,
          yEnd,
        )
        ..lineTo(xStart + ancho * 0.5, yEnd)
        ..quadraticBezierTo(
          xStart + ancho * 0.4 + (rng.nextDouble() - 0.5) * 4,
          (yStart + yEnd) * 0.5,
          xStart + ancho,
          yStart,
        )
        ..close();
      canvas.drawPath(
        dripPath,
        Paint()
          ..color = _calClara.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
      // Pequeña gota seca en la punta.
      canvas.drawCircle(
        Offset(xStart, yEnd + 1),
        ancho * 0.5,
        Paint()
          ..color = _calClara.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
    }

    // 3. Motas pequeñas (oscuras y claras esparcidas).
    for (var i = 0; i < 32; i++) {
      final cx = w * 0.13 + rng.nextDouble() * w * 0.74;
      final cy = cuerpoTop + 3 + rng.nextDouble() * (bodyHeight - 6);
      final radio = 0.4 + rng.nextDouble() * 1.0;
      final esOscura = rng.nextDouble() < 0.65;
      canvas.drawCircle(
        Offset(cx, cy),
        radio,
        Paint()
          ..color = (esOscura
                  ? const Color(0xFF3A1F0E)
                  : const Color(0xFFE0AA80))
              .withValues(alpha: 0.40 + rng.nextDouble() * 0.4),
      );
    }

    // 4. Hairline scratches (rayones finos del uso/manipulación).
    for (var i = 0; i < 4; i++) {
      final x1 = w * 0.20 + rng.nextDouble() * w * 0.60;
      final y1 = cuerpoTop + 5 + rng.nextDouble() * (bodyHeight - 10);
      final largo = 9.0 + rng.nextDouble() * 18;
      final angulo = (rng.nextDouble() - 0.5) * 0.9;
      final x2 = x1 + cos(angulo) * largo;
      final y2 = y1 + sin(angulo) * largo;
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = _terracotaSombra.withValues(alpha: 0.40)
          ..strokeWidth = 0.5,
      );
    }

    // 5. Musgo / algas en la base (humedad acumulada).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.30, macetaBottom - bodyHeight * 0.10),
        width: 26,
        height: 9,
      ),
      Paint()
        ..color = _musgo.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.72, macetaBottom - bodyHeight * 0.08),
        width: 18,
        height: 7,
      ),
      Paint()
        ..color = _musgoOscuro.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Pequeñas motitas de musgo.
    for (var i = 0; i < 8; i++) {
      final cx = w * 0.18 + rng.nextDouble() * w * 0.64;
      final cy = macetaBottom - 4 - rng.nextDouble() * bodyHeight * 0.20;
      canvas.drawCircle(
        Offset(cx, cy),
        0.6 + rng.nextDouble() * 0.8,
        Paint()
          ..color = _musgo.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pinta el jazmín en su etapa actual de crecimiento.
///
/// Diseño basado en jazmines reales (Jasminum polyanthum / officinale):
///  · Tallo principal vertical con ramas laterales que emergen al
///    crecer la planta.
///  · **Hojas palmadas** (5 lóbulos radiando desde el peciolo).
///  · **Clusters** de pequeñas flores blancas (no flores individuales
///    grandes) en las puntas del tallo y las ramas.
///
/// Etapas (en función de `progreso` 0..1):
///   0.00–0.10: brote inicial (visible desde el primer día — tallo
///              corto verde brillante con 2 hojitas).
///   0.10–0.30: tallo crece, aparecen hojas palmadas pequeñas.
///   0.30–0.50: emerge la primera rama lateral.
///   0.50–0.65: emerge la segunda rama lateral.
///   0.65–0.85: capullos formándose en las puntas.
///   0.85–1.00: clusters de flores abriéndose completamente.
class JazminPainter extends CustomPainter {
  final double progreso;
  final double marchitez;
  final double tiempoAnimacion;
  final PeriodoDia periodo;

  const JazminPainter({
    required this.progreso,
    required this.marchitez,
    this.tiempoAnimacion = 0.0,
    this.periodo = PeriodoDia.dia,
  });

  // Paleta verde (más vivo cuando joven, más oscuro al madurar).
  static const Color _verdeJoven = Color(0xFF6FA84A);
  static const Color _verdeMaduro = Color(0xFF4A6B3A);
  static const Color _verdeOscuro = Color(0xFF2E4A24);
  static const Color _verdeMarchito = Color(0xFF7A6438);
  static const Color _verdeOscMarchito = Color(0xFF3A2A18);
  // Madera/tallo leñoso (sólo visible cuando la planta es adulta).
  static const Color _marronTallo = Color(0xFF6A4B30);
  // Flores blancas con centro amarillo.
  static const Color _blancoFlor = Color(0xFFFCF7EE);
  static const Color _cremaFlor = Color(0xFFE8DECF);
  static const Color _amarilloCentro = Color(0xFFE8C868);

  /// Posición vertical (en fracción del alto) donde está la tierra en
  /// el canvas compartido con la maceta-imagen. Soil sits at ~0.64 of
  /// canvas height (matching maceta.png's rim).
  static const double nivelTierra = 0.64;

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso <= 0) return;

    final w = size.width;
    final h = size.height;
    final base = Offset(w * 0.5, h * nivelTierra);

    // Inclinación por marchitez + balanceo natural sutil.
    canvas.save();
    final balanceo = sin(tiempoAnimacion) * 0.012;
    final inclinacion = marchitez * 0.40 + balanceo;
    canvas.translate(base.dx, base.dy);
    canvas.rotate(inclinacion);
    canvas.translate(-base.dx, -base.dy);

    // Colores ajustados a marchitez + periodo (luz ambiente).
    final tinte = FiltrosAmbiente.tinteJazmin(periodo);
    final intensidadTinte = FiltrosAmbiente.intensidadTinteJazmin(periodo);

    // Verde "actual": empieza siendo brillante (brote joven) y se va
    // oscureciendo a medida que la planta madura.
    final verdeBase = Color.lerp(_verdeJoven, _verdeMaduro, progreso)!;
    final verdeOscBase = _verdeOscuro;

    final verdeSano = Color.lerp(verdeBase, _verdeMarchito, marchitez)!;
    final verdeOscSano =
        Color.lerp(verdeOscBase, _verdeOscMarchito, marchitez)!;

    final verde = Color.lerp(verdeSano, tinte, intensidadTinte)!;
    final verdeOsc = Color.lerp(verdeOscSano, tinte, intensidadTinte)!;
    final marron = Color.lerp(_marronTallo, tinte, intensidadTinte * 0.5)!;

    // Alto máximo del tallo — más corto que antes (no llega al techo
    // del canvas) para que la planta luzca compacta y bien proporcionada.
    final maxAlto = base.dy - h * 0.30;
    final altoTallo = maxAlto * progreso.clamp(0.10, 1.0);

    final puntaTallo = Offset(
      base.dx + sin(tiempoAnimacion * 0.7) * 1.5,
      base.dy - altoTallo,
    );

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1. TALLO PRINCIPAL (más grueso a medida que crece)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _dibujarTallo(
      canvas, base, puntaTallo,
      grosor: 2.4 + progreso * 1.6,
      colorPrincipal: progreso < 0.5
          ? verdeOsc
          : Color.lerp(verdeOsc, marron, (progreso - 0.5) * 1.4)!,
    );

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 2. HOJAS PALMADAS en el tallo principal
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Cada entrada: (posiciónEnTallo 0..1, ladoIzq?, escala, progresoMin)
    // Distribución escalonada (no se amontonan en el medio):
    final hojasPrincipal = [
      _HojaConfig(0.10, true, 0.80, 0.03), // brote inicial — visible día 1
      _HojaConfig(0.22, false, 0.90, 0.14),
      _HojaConfig(0.36, true, 1.00, 0.26),
      _HojaConfig(0.50, false, 1.10, 0.40),
      _HojaConfig(0.65, true, 1.05, 0.54),
      _HojaConfig(0.80, false, 0.95, 0.68),
    ];

    for (final h_ in hojasPrincipal) {
      if (progreso < h_.progresoMin) continue;
      final factorAparicion =
          ((progreso - h_.progresoMin) / 0.10).clamp(0.0, 1.0);
      final centro = Offset(
        base.dx + (h_.izquierda ? -3 : 3),
        base.dy - altoTallo * h_.posicionTallo,
      );
      _dibujarHojaPalmada(
        canvas, centro,
        angulo: h_.izquierda ? -pi / 2.3 : pi / 2.3,
        escala: h_.escala * factorAparicion * (1 + progreso * 0.4),
        verde: verde, verdeOsc: verdeOsc,
      );
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 3. CLUSTER DE FLORES en la punta del tallo
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Sin ramas laterales — solo un único racimo denso en lo alto del
    // tallo principal cuando el jazmín está suficientemente crecido.
    final mFactor = 1.0 - marchitez * 0.6;
    if (progreso > 0.65) {
      final p = ((progreso - 0.65) / 0.30).clamp(0.0, 1.0) * mFactor;
      _dibujarCluster(canvas, puntaTallo, w * 0.22, p);
    }

    canvas.restore();
  }

  /// Dibuja un tallo (línea curva) desde un punto a otro.
  void _dibujarTallo(
    Canvas canvas,
    Offset desde,
    Offset hasta, {
    required double grosor,
    required Color colorPrincipal,
  }) {
    final dx = hasta.dx - desde.dx;
    final dy = hasta.dy - desde.dy;
    // Punto de control con leve desvío perpendicular para curva natural.
    final control = Offset(
      desde.dx + dx * 0.4 + sin(tiempoAnimacion * 0.4) * 1.5,
      desde.dy + dy * 0.5,
    );
    final path = Path()
      ..moveTo(desde.dx, desde.dy)
      ..quadraticBezierTo(control.dx, control.dy, hasta.dx, hasta.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = colorPrincipal
        ..strokeWidth = grosor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Dibuja una hoja palmada con **5 lóbulos** radiando desde el peciolo.
  /// Estilo similar a la hoja de jazmín / hiedra ornamental.
  void _dibujarHojaPalmada(
    Canvas canvas,
    Offset centro, {
    required double angulo,
    required double escala,
    required Color verde,
    required Color verdeOsc,
  }) {
    if (escala <= 0) return;
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(angulo);
    canvas.scale(escala);

    // Peciolo (tallito que conecta con el tallo principal).
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(0, -2),
      Paint()
        ..color = verdeOsc
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // 5 lóbulos radiando desde el peciolo (-π/2 = arriba).
    // Cada lóbulo es un óvalo puntiagudo.
    const lobeAngles = [-1.0, -0.5, 0.0, 0.5, 1.0];
    const lobeLengths = [9.0, 11.0, 12.0, 11.0, 9.0]; // central más largo
    const lobeWidths = [3.0, 3.5, 3.8, 3.5, 3.0];

    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(lobeAngles[i]);
      _dibujarLobulo(
        canvas,
        largo: lobeLengths[i],
        ancho: lobeWidths[i],
        verde: verde,
        verdeOsc: verdeOsc,
      );
      canvas.restore();
    }

    // Pequeño punto en el centro (donde se unen los lóbulos).
    canvas.drawCircle(
      const Offset(0, -2),
      0.8,
      Paint()..color = verdeOsc,
    );

    canvas.restore();
  }

  /// Dibuja un lóbulo individual de hoja palmada. El lóbulo apunta
  /// hacia arriba en el sistema de coordenadas local (después de rotar).
  void _dibujarLobulo(
    Canvas canvas, {
    required double largo,
    required double ancho,
    required Color verde,
    required Color verdeOsc,
  }) {
    final path = Path()
      ..moveTo(0, -2)
      // Curva derecha hacia la punta
      ..quadraticBezierTo(ancho * 0.7, -largo * 0.3, ancho * 0.4, -largo * 0.85)
      ..quadraticBezierTo(0, -largo, -ancho * 0.4, -largo * 0.85)
      ..quadraticBezierTo(-ancho * 0.7, -largo * 0.3, 0, -2)
      ..close();

    // Relleno con gradiente vertical (más claro arriba).
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [verdeOsc, verde],
        ).createShader(Rect.fromLTWH(-ancho, -largo, ancho * 2, largo)),
    );

    // Contorno fino para definirlo.
    canvas.drawPath(
      path,
      Paint()
        ..color = verdeOsc.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Vena central.
    canvas.drawLine(
      const Offset(0, -2),
      Offset(0, -largo * 0.85),
      Paint()
        ..color = verdeOsc.withValues(alpha: 0.55)
        ..strokeWidth = 0.5,
    );
  }

  /// Dibuja un **cluster** de pequeñas flores blancas (5-7 flores en
  /// un grupo apretado). [apertura] de 0 a 1 controla cuántas flores
  /// están abiertas y de qué tamaño.
  void _dibujarCluster(
    Canvas canvas,
    Offset centro,
    double tamanoCluster,
    double apertura,
  ) {
    if (apertura <= 0) return;

    canvas.save();
    canvas.translate(centro.dx, centro.dy);

    // Colores afectados por marchitez + tinte ambiente.
    final tinte = FiltrosAmbiente.tinteJazmin(periodo);
    final intensidadTinte = FiltrosAmbiente.intensidadTinteJazmin(periodo);
    final blancoBase =
        Color.lerp(_blancoFlor, const Color(0xFF8A6650), marchitez)!;
    final cremaBase =
        Color.lerp(_cremaFlor, const Color(0xFF5A4030), marchitez)!;
    final amarilloBase =
        Color.lerp(_amarilloCentro, const Color(0xFF6A5028), marchitez)!;
    final blanco = Color.lerp(blancoBase, tinte, intensidadTinte)!;
    final crema = Color.lerp(cremaBase, tinte, intensidadTinte)!;
    final amarillo = Color.lerp(amarilloBase, tinte, intensidadTinte * 0.6)!;

    // 12 posiciones en anillos concéntricos: 1 central + 5 medias
    // + 6 exteriores. Apertura escalonada para llenado gradual del
    // cluster a lo largo de los días 9-14.
    final posiciones = [
      // ─── ANILLO 0 (central) ───
      _PosFlorCluster(0.00, 0.00, 1.00, 0.05),
      // ─── ANILLO 1 (medio, radio 0.30) — 5 flores ───
      _PosFlorCluster(-0.30, 0.00, 0.95, 0.15),     // mid-left
      _PosFlorCluster(0.30, 0.00, 0.95, 0.15),      // mid-right
      _PosFlorCluster(-0.20, -0.28, 0.92, 0.22),    // mid-upper-left
      _PosFlorCluster(0.20, -0.28, 0.92, 0.22),     // mid-upper-right
      _PosFlorCluster(0.00, 0.30, 0.90, 0.30),      // mid-bottom
      // ─── ANILLO 2 (exterior, radio 0.55) — 6 flores ───
      _PosFlorCluster(-0.50, -0.20, 0.85, 0.42),    // outer-left
      _PosFlorCluster(0.50, -0.20, 0.85, 0.45),     // outer-right
      _PosFlorCluster(-0.32, -0.50, 0.82, 0.55),    // outer-upper-left
      _PosFlorCluster(0.32, -0.50, 0.82, 0.60),     // outer-upper-right
      _PosFlorCluster(0.00, -0.60, 0.80, 0.70),     // outer-top
      _PosFlorCluster(0.00, 0.55, 0.80, 0.78),      // outer-bottom
    ];

    // Flores ~50 % más pequeñas que antes (0.30 → 0.16) para que
    // las 12 quepan en el cluster sin solaparse demasiado.
    final radioBase = tamanoCluster * 0.16;

    for (var i = 0; i < posiciones.length; i++) {
      final p = posiciones[i];
      if (apertura < p.aparece) continue;
      final pApertura =
          ((apertura - p.aparece) / 0.15).clamp(0.0, 1.0);
      final dx = p.xRel * tamanoCluster +
          sin(tiempoAnimacion + i * 1.3) * 0.6;
      final dy = p.yRel * tamanoCluster +
          cos(tiempoAnimacion + i * 0.7) * 0.4;
      _dibujarFlorPequena(
        canvas,
        Offset(dx, dy),
        radioBase * p.escala * pApertura,
        blanco, crema, amarillo,
      );
    }

    canvas.restore();
  }

  /// Una flor pequeña individual (5 pétalos + centro amarillo).
  /// Llamada desde [_dibujarCluster] para construir los racimos.
  void _dibujarFlorPequena(
    Canvas canvas,
    Offset centro,
    double radio,
    Color blanco,
    Color crema,
    Color amarillo,
  ) {
    if (radio <= 0.3) return;
    // Garantizar mínimo legible para que las flores se vean a tamaño
    // pequeño dentro del cluster denso.
    final r = radio.clamp(1.2, double.infinity);

    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(centro.dx * 0.04);

    // 5 pétalos como círculos solapados — más compactos para que
    // cada flor pequeña sea claramente reconocible.
    final separacion = r * 0.78;
    final radioPetalo = r * 0.62;

    for (var i = 0; i < 5; i++) {
      final ang = (i * 2 * pi / 5) - pi / 2;
      final px = cos(ang) * separacion;
      final py = sin(ang) * separacion;
      canvas.drawCircle(
        Offset(px, py),
        radioPetalo,
        Paint()
          ..shader = RadialGradient(
            colors: [blanco, crema],
            stops: const [0.4, 1.0],
          ).createShader(Rect.fromCircle(
            center: Offset(px, py),
            radius: radioPetalo,
          )),
      );
      // Contorno muy sutil del pétalo.
      canvas.drawCircle(
        Offset(px, py),
        radioPetalo,
        Paint()
          ..color = crema.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4,
      );
    }

    // Centro amarillo.
    canvas.drawCircle(
      Offset.zero,
      r * 0.32,
      Paint()..color = amarillo,
    );
    // Pequeño brillo.
    canvas.drawCircle(
      Offset(-r * 0.08, -r * 0.08),
      r * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant JazminPainter old) =>
      old.progreso != progreso ||
      old.marchitez != marchitez ||
      old.tiempoAnimacion != tiempoAnimacion ||
      old.periodo != periodo;
}

/// Configuración de una hoja palmada en el tallo principal.
class _HojaConfig {
  /// Posición en el tallo principal (0 = base, 1 = punta).
  final double posicionTallo;
  /// Si va al lado izquierdo del tallo.
  final bool izquierda;
  /// Tamaño relativo de la hoja.
  final double escala;
  /// Mínimo de `progreso` necesario para que esta hoja aparezca.
  final double progresoMin;

  const _HojaConfig(
      this.posicionTallo, this.izquierda, this.escala, this.progresoMin);
}

/// Posición de una flor dentro de un cluster.
class _PosFlorCluster {
  /// Offset horizontal relativo al cluster (-1..1).
  final double xRel;
  /// Offset vertical relativo al cluster (-1..1).
  final double yRel;
  /// Tamaño relativo de la flor.
  final double escala;
  /// Apertura mínima del cluster para que esta flor aparezca.
  final double aparece;

  const _PosFlorCluster(this.xRel, this.yRel, this.escala, this.aparece);
}

// ═══════════════════════════════════════════════════════════════════════
//  ICONOS PERSONALIZADOS — line-art vintage en oro/granate
// ═══════════════════════════════════════════════════════════════════════
//
// Reemplazan a los emojis 🔥 🌸 🎂 que se ven demasiado modernos. Estos
// son CustomPainter delicados, en color oroClaro, que se integran con
// la paleta vintage de la app.

/// Llamita estilizada para indicar "racha".
class IconoLlama extends StatelessWidget {
  final double size;
  final Color color;

  const IconoLlama({
    super.key,
    this.size = 14,
    this.color = AppColors.oroClaro,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LlamaPainter(color: color)),
    );
  }
}

class _LlamaPainter extends CustomPainter {
  final Color color;
  const _LlamaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Forma de llama: punta arriba, base redondeada con doble curva interior.
    final llamaPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      // Curva derecha hacia abajo
      ..cubicTo(w * 0.85, h * 0.30, w * 0.95, h * 0.55, w * 0.78, h * 0.78)
      // Curva derecha-baja redondeada
      ..cubicTo(w * 0.72, h * 0.95, w * 0.55, h * 0.99, w * 0.5, h * 0.92)
      // Curva izquierda-baja redondeada (espejo)
      ..cubicTo(w * 0.45, h * 0.99, w * 0.28, h * 0.95, w * 0.22, h * 0.78)
      // Curva izquierda hacia arriba
      ..cubicTo(w * 0.05, h * 0.55, w * 0.15, h * 0.30, w * 0.5, h * 0.05)
      ..close();

    // Llamita interior (más pequeña, sugiere doble llama).
    final llamaInterior = Path()
      ..moveTo(w * 0.5, h * 0.40)
      ..cubicTo(w * 0.65, h * 0.55, w * 0.68, h * 0.72, w * 0.5, h * 0.85)
      ..cubicTo(w * 0.32, h * 0.72, w * 0.35, h * 0.55, w * 0.5, h * 0.40)
      ..close();

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(llamaPath, stroke);
    canvas.drawPath(
      llamaInterior,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _LlamaPainter old) => old.color != color;
}

/// Flor de jazmín pequeña estilizada — para indicar "ramo".
class IconoJazminMini extends StatelessWidget {
  final double size;
  final Color color;

  const IconoJazminMini({
    super.key,
    this.size = 14,
    this.color = AppColors.oroClaro,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _JazminMiniPainter(color: color)),
    );
  }
}

class _JazminMiniPainter extends CustomPainter {
  final Color color;
  const _JazminMiniPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centro = Offset(w * 0.5, h * 0.5);
    final radio = w * 0.42;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round;

    // 5 pétalos en estrella (jazmín).
    for (var i = 0; i < 5; i++) {
      final angulo = (i * 2 * pi / 5) - pi / 2;
      final petalo = Path()
        ..moveTo(centro.dx, centro.dy)
        ..quadraticBezierTo(
          centro.dx + cos(angulo - 0.4) * radio * 0.5,
          centro.dy + sin(angulo - 0.4) * radio * 0.5,
          centro.dx + cos(angulo) * radio,
          centro.dy + sin(angulo) * radio,
        )
        ..quadraticBezierTo(
          centro.dx + cos(angulo + 0.4) * radio * 0.5,
          centro.dy + sin(angulo + 0.4) * radio * 0.5,
          centro.dx,
          centro.dy,
        )
        ..close();
      canvas.drawPath(petalo, stroke);
    }

    // Centro.
    canvas.drawCircle(
      centro,
      w * 0.08,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _JazminMiniPainter old) => old.color != color;
}

/// Pequeño corazón con detalle ornamental — para indicar "cumpleaños".
class IconoCorazonOrnamentado extends StatelessWidget {
  final double size;
  final Color color;

  const IconoCorazonOrnamentado({
    super.key,
    this.size = 14,
    this.color = AppColors.oroClaro,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CorazonPainter(color: color)),
    );
  }
}

class _CorazonPainter extends CustomPainter {
  final Color color;
  const _CorazonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Corazón clásico vintage.
    final corazon = Path()
      ..moveTo(w * 0.5, h * 0.30)
      ..cubicTo(w * 0.20, h * 0.05, w * -0.05, h * 0.50, w * 0.5, h * 0.95)
      ..cubicTo(w * 1.05, h * 0.50, w * 0.80, h * 0.05, w * 0.5, h * 0.30)
      ..close();

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(corazon, stroke);

    // Pequeña curva de "destello" interior.
    final brillo = Path()
      ..moveTo(w * 0.32, h * 0.35)
      ..quadraticBezierTo(w * 0.28, h * 0.50, w * 0.38, h * 0.62);
    canvas.drawPath(
      brillo,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _CorazonPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════
//  MESITA REDONDA VINTAGE
// ═══════════════════════════════════════════════════════════════════════
//
// Mesita pequeña de pedestal central, estilo art-déco / vintage. Madera
// oscura tipo nogal con detalles dorados sutiles. Comparte canvas con
// la maceta y el jazmín — ocupa la franja inferior y ∈ [0.78, 1.00].

class MesitaPainter extends CustomPainter {
  const MesitaPainter();

  // Paleta de madera vintage.
  static const Color _maderaClara = Color(0xFF7A4A2E);
  static const Color _maderaMedia = Color(0xFF5A3520);
  static const Color _maderaOscura = Color(0xFF3E2010);
  static const Color _maderaSombra = Color(0xFF1F0F08);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Geometría de la mesita en la franja inferior del canvas.
    final tableroTop = h * 0.770;       // borde superior del tablero
    final tableroAlto = h * 0.025;       // grosor del tablero
    final tableroBottom = tableroTop + tableroAlto;
    final pedestalTop = tableroBottom;
    final pedestalBottom = h * 0.965;
    final tableroIzq = w * 0.16;
    final tableroDer = w * 0.84;
    final pedestalAncho = w * 0.10;
    final centroX = w * 0.5;

    // 1. Sombra debajo de la mesita.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centroX, h * 0.985),
        width: w * 0.50,
        height: 9,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2. Base/pie ancho de la mesa (elipse).
    final piePath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(centroX, pedestalBottom),
        width: w * 0.46,
        height: h * 0.040,
      ));
    canvas.drawPath(
      piePath,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          colors: [_maderaClara, _maderaMedia, _maderaOscura],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCenter(
          center: Offset(centroX, pedestalBottom),
          width: w * 0.46,
          height: h * 0.040,
        )),
    );
    // Filete dorado fino sobre el borde del pie.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centroX, pedestalBottom),
        width: w * 0.44,
        height: h * 0.038,
      ),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFFB89A6A).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 3. Pedestal central (columna ornamental).
    final pedRect = Rect.fromLTRB(
      centroX - pedestalAncho / 2,
      pedestalTop,
      centroX + pedestalAncho / 2,
      pedestalBottom - h * 0.010,
    );
    canvas.drawRect(
      pedRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _maderaSombra,
            _maderaClara,
            _maderaOscura,
          ],
          stops: [0.0, 0.4, 1.0],
        ).createShader(pedRect),
    );

    // Anillos decorativos en el pedestal (toque ornamental).
    for (final yRel in [0.15, 0.85]) {
      final y = pedestalTop + (pedestalBottom - pedestalTop) * yRel;
      canvas.drawRect(
        Rect.fromLTRB(
          centroX - pedestalAncho / 2 - 1.5,
          y - 1.5,
          centroX + pedestalAncho / 2 + 1.5,
          y + 1.5,
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_maderaClara, _maderaSombra],
          ).createShader(Rect.fromLTWH(0, y - 1.5, w, 3)),
      );
    }

    // 4. Tablero redondo (elipse con perspectiva 3D).
    // Sombra inferior del tablero (debajo de la madera).
    final tableroBottomEllipse = Rect.fromLTRB(
      tableroIzq,
      tableroBottom - tableroAlto * 0.4,
      tableroDer,
      tableroBottom + tableroAlto * 0.5,
    );
    canvas.drawOval(
      tableroBottomEllipse,
      Paint()..color = _maderaSombra,
    );

    // Cara superior del tablero (elipse plana visible desde arriba).
    final tableroTopEllipse = Rect.fromLTRB(
      tableroIzq,
      tableroTop - tableroAlto * 0.6,
      tableroDer,
      tableroTop + tableroAlto * 0.4,
    );
    canvas.drawOval(
      tableroTopEllipse,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [_maderaClara, _maderaMedia, _maderaOscura],
          stops: [0.0, 0.55, 1.0],
        ).createShader(tableroTopEllipse),
    );

    // Filete dorado fino alrededor del tablero (borde superior).
    canvas.drawOval(
      tableroTopEllipse,
      Paint()
        ..color = const Color(0xFFB89A6A).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Sutiles vetas de madera en el tablero (textura).
    final rng = Random(11);
    for (var i = 0; i < 5; i++) {
      final yC = tableroTop - tableroAlto * 0.4 +
          rng.nextDouble() * tableroAlto;
      final x1 = tableroIzq + 12 + rng.nextDouble() * 30;
      final x2 = tableroDer - 12 - rng.nextDouble() * 30;
      canvas.drawLine(
        Offset(x1, yC),
        Offset(x2, yC),
        Paint()
          ..color = _maderaSombra.withValues(alpha: 0.25)
          ..strokeWidth = 0.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════
//  RAMO — jarrón estilo vector/cartoon con jazmines recolectados
// ═══════════════════════════════════════════════════════════════════════
//
// Diseño ilustrativo plano: cuerpo dorado-crema con CONTORNO definido,
// flores tipo "doodle" con pétalos circulares y centro amarillo, hojitas
// verdes y un balanceo continuo de las flores. Pensado para verse bien
// sobre fondos oscuros (panel granate) y a tamaños pequeños.

class RamoPainter extends CustomPainter {
  /// Número de jazmines recolectados (0 a [floresTotal]).
  final int flores;

  /// Capacidad total del ramo (5 por defecto).
  final int floresTotal;

  /// Para animar el balanceo continuo de las flores.
  final double tiempoAnimacion;

  const RamoPainter({
    required this.flores,
    this.floresTotal = 5,
    this.tiempoAnimacion = 0.0,
  });

  // Paleta vector/cartoon.
  static const Color _contorno = Color(0xFF2A1810);     // contorno marrón muy oscuro
  static const Color _vasoClaro = Color(0xFFE8D29C);    // crema dorado claro
  static const Color _vasoOscuro = Color(0xFFB89460);   // crema dorado sombra
  static const Color _vasoBanda = Color(0xFFD4B070);    // banda decorativa
  static const Color _floClaro = Color(0xFFFCF6E6);     // blanco crema
  static const Color _floCentro = Color(0xFFF0B848);    // amarillo doodle
  static const Color _talloVerde = Color(0xFF6A9040);   // verde tallos
  static const Color _hojaVerde = Color(0xFF7AA850);    // verde hojas claro

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Adaptamos el tamaño del jarrón al canvas (puede ser estrecho o ancho).
    final vasoW = min(w * 0.62, h * 0.45);
    final vasoH = vasoW * 0.95;
    final vasoBottom = h - 4;
    final vasoTop = vasoBottom - vasoH;

    // Balanceo global del ramo (muy sutil).
    final balanceo = sin(tiempoAnimacion * 0.4) * 0.8;

    canvas.save();
    canvas.translate(balanceo, 0);

    // ───── JARRÓN cartoon ─────
    _dibujarJarron(canvas, cx, vasoTop, vasoBottom, vasoW, vasoH);

    canvas.restore();

    // ───── FLORES y TALLOS ─────
    if (flores > 0) {
      _dibujarRamoFlores(
        canvas, w, h, cx, vasoTop, vasoW,
      );
    }
  }

  /// Dibuja el jarrón con forma chubby (cuello estrecho, cuerpo redondeado)
  /// y un contorno marrón oscuro bien marcado tipo doodle.
  void _dibujarJarron(
    Canvas canvas,
    double cx,
    double top,
    double bottom,
    double w,
    double h,
  ) {
    final halfW = w / 2;

    // Path del jarrón — chubby cartoon (cuello estrecho, cuerpo bulboso).
    final p = Path()
      // Top-left de la boca (lip ligeramente abocinado).
      ..moveTo(cx - halfW * 0.70, top)
      ..quadraticBezierTo(
          cx - halfW * 0.78, top + 3, cx - halfW * 0.65, top + 8)
      // Cuello: se estrecha hacia adentro.
      ..quadraticBezierTo(
          cx - halfW * 0.45, top + h * 0.18,
          cx - halfW * 0.45, top + h * 0.32)
      // Cuerpo: se abomba.
      ..quadraticBezierTo(
          cx - halfW * 1.05, top + h * 0.55,
          cx - halfW * 0.78, top + h * 0.86)
      // Base redondeada.
      ..quadraticBezierTo(
          cx - halfW * 0.72, bottom, cx - halfW * 0.50, bottom)
      ..lineTo(cx + halfW * 0.50, bottom)
      ..quadraticBezierTo(
          cx + halfW * 0.72, bottom, cx + halfW * 0.78, top + h * 0.86)
      // Vuelta por el lado derecho (espejo).
      ..quadraticBezierTo(
          cx + halfW * 1.05, top + h * 0.55,
          cx + halfW * 0.45, top + h * 0.32)
      ..quadraticBezierTo(
          cx + halfW * 0.45, top + h * 0.18,
          cx + halfW * 0.65, top + 8)
      ..quadraticBezierTo(
          cx + halfW * 0.78, top + 3, cx + halfW * 0.70, top)
      ..close();

    // Relleno: degradado dorado-crema 2 tonos (cartoon).
    canvas.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [_vasoClaro, _vasoOscuro],
        ).createShader(Rect.fromLTWH(cx - halfW, top, w, h)),
    );

    // Highlight muy sutil en el lado izquierdo (toque de luz).
    final highlight = Path()
      ..moveTo(cx - halfW * 0.55, top + h * 0.30)
      ..quadraticBezierTo(
          cx - halfW * 0.80, top + h * 0.55,
          cx - halfW * 0.62, top + h * 0.80)
      ..quadraticBezierTo(
          cx - halfW * 0.55, top + h * 0.55,
          cx - halfW * 0.40, top + h * 0.30)
      ..close();
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );

    // CONTORNO marrón oscuro — el rasgo cartoon principal.
    canvas.drawPath(
      p,
      Paint()
        ..color = _contorno
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Banda decorativa horizontal alrededor del cuello.
    final bandaY = top + h * 0.26;
    canvas.drawLine(
      Offset(cx - halfW * 0.5, bandaY),
      Offset(cx + halfW * 0.5, bandaY),
      Paint()
        ..color = _vasoBanda
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx - halfW * 0.5, bandaY),
      Offset(cx + halfW * 0.5, bandaY),
      Paint()
        ..color = _contorno
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Dibuja los tallos y flores saliendo del cuello del jarrón.
  ///
  /// El cluster de flores se posiciona **relativo al tamaño del jarrón**,
  /// no a la altura del canvas — así el ramo queda compacto encima del
  /// jarrón sin tallos kilométricos cuando el canvas es alto.
  void _dibujarRamoFlores(
    Canvas canvas,
    double w,
    double h,
    double cx,
    double vasoTop,
    double vasoW,
  ) {
    // Dimensiones del cluster de flores (encima del jarrón).
    final clusterAlto = vasoW * 1.20;   // alto del abanico de flores
    final clusterAncho = vasoW * 1.40;  // ancho del abanico

    // Posiciones absolutas (yPos = coordenada Y del centro de cada flor).
    final posiciones = [
      // Central — la más alta del ramo.
      _PosFlorRamo(0, vasoTop - clusterAlto * 0.85, 1.00),
      // Laterales bajos (cerca del cuello).
      _PosFlorRamo(-clusterAncho * 0.38, vasoTop - clusterAlto * 0.25, 0.85),
      _PosFlorRamo(clusterAncho * 0.38, vasoTop - clusterAlto * 0.30, 0.85),
      // Laterales altos.
      _PosFlorRamo(-clusterAncho * 0.20, vasoTop - clusterAlto * 1.05, 0.92),
      _PosFlorRamo(clusterAncho * 0.20, vasoTop - clusterAlto * 1.00, 0.92),
    ];

    // Punto de salida común desde el cuello del jarrón.
    final origen = Offset(cx, vasoTop + 4);

    // Tallos PRIMERO (las flores los taparán en la unión).
    for (var i = 0; i < flores && i < posiciones.length; i++) {
      final p = posiciones[i];
      final wob = sin(tiempoAnimacion + i * 1.6) * 1.5;
      final puntaX = cx + p.xOffset + wob;
      final puntaY = p.yPos;

      final tallo = Path()
        ..moveTo(origen.dx, origen.dy)
        ..quadraticBezierTo(
          cx + p.xOffset * 0.3,
          (origen.dy + puntaY) * 0.55,
          puntaX,
          puntaY + 6,
        );

      // Contorno (debajo).
      canvas.drawPath(
        tallo,
        Paint()
          ..color = _contorno
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      // Verde (encima del contorno → efecto borde).
      canvas.drawPath(
        tallo,
        Paint()
          ..color = _talloVerde
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Una hojita en los tallos más exteriores (laterales bajos).
      if (i == 1 || i == 2) {
        final hojaCenter = Offset(
          cx + p.xOffset * 0.55,
          (origen.dy + puntaY) * 0.58,
        );
        _dibujarHojita(canvas, hojaCenter, p.xOffset < 0 ? -1 : 1,
            vasoW * 0.16);
      }
    }

    // FLORES encima.
    for (var i = 0; i < flores && i < posiciones.length; i++) {
      final p = posiciones[i];
      final wob = sin(tiempoAnimacion + i * 1.6) * 1.5;
      final cyF = p.yPos;
      _dibujarFlorCartoon(
        canvas,
        Offset(cx + p.xOffset + wob, cyF),
        vasoW * 0.32 * p.escala,
      );
    }
  }

  /// Flor doodle: 5 pétalos circulares + centro amarillo, todo con contorno.
  void _dibujarFlorCartoon(Canvas canvas, Offset centro, double tamano) {
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    // Ligera rotación para variedad.
    canvas.rotate(centro.dx * 0.03);

    final radioPetalo = tamano * 0.38;
    final separacion = tamano * 0.36;

    final fill = Paint()..color = _floClaro;
    final outline = Paint()
      ..color = _contorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // 1) Relleno de los 5 pétalos (todos antes de los contornos para que
    //    los strokes se solapen limpios).
    for (var i = 0; i < 5; i++) {
      final ang = (i * 2 * pi / 5) - pi / 2;
      final px = cos(ang) * separacion;
      final py = sin(ang) * separacion;
      canvas.drawCircle(Offset(px, py), radioPetalo, fill);
    }
    // 2) Contornos.
    for (var i = 0; i < 5; i++) {
      final ang = (i * 2 * pi / 5) - pi / 2;
      final px = cos(ang) * separacion;
      final py = sin(ang) * separacion;
      canvas.drawCircle(Offset(px, py), radioPetalo, outline);
    }

    // Centro amarillo con contorno.
    canvas.drawCircle(
        Offset.zero, tamano * 0.22, Paint()..color = _floCentro);
    canvas.drawCircle(Offset.zero, tamano * 0.22, outline);

    canvas.restore();
  }

  /// Hojita verde tipo doodle con contorno marrón.
  void _dibujarHojita(
      Canvas canvas, Offset centro, int direccion, double largo) {
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(direccion * pi / 4.5);

    final ancho = largo * 0.5;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(ancho, -largo * 0.45, largo, 0)
      ..quadraticBezierTo(ancho, largo * 0.45, 0, 0)
      ..close();

    // Relleno verde.
    canvas.drawPath(path, Paint()..color = _hojaVerde);
    // Contorno marrón.
    canvas.drawPath(
      path,
      Paint()
        ..color = _contorno
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    // Vena central.
    canvas.drawLine(
      const Offset(2, 0),
      Offset(largo - 2, 0),
      Paint()
        ..color = _contorno.withValues(alpha: 0.5)
        ..strokeWidth = 0.8,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RamoPainter old) =>
      old.flores != flores || old.tiempoAnimacion != tiempoAnimacion;
}

class _PosFlorRamo {
  /// Desplazamiento horizontal desde el centro del jarrón.
  final double xOffset;

  /// Posición Y absoluta en el canvas.
  final double yPos;

  /// Escala de la flor (1.0 = tamaño base).
  final double escala;

  const _PosFlorRamo(this.xOffset, this.yPos, this.escala);
}
