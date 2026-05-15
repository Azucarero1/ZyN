import 'package:flutter/material.dart';

import 'fondo_jardin.dart';

/// Renderiza la maceta a partir de la imagen `assets/images/maceta.png`,
/// aplicando el filtro de color del periodo del día (día / atardecer /
/// noche) para que la luz coincida con la del fondo.
///
/// La imagen es un PNG cuadrado (1024×1024) con la maceta ocupando
/// aproximadamente toda el área visible y la tierra visible en la parte
/// superior. Se ancla al borde inferior del SizedBox que la contiene
/// para que su base toque exactamente la mesa de la imagen de fondo.
///
/// Encima de la maceta el [JazminPainter] dibuja la planta procedural;
/// su `nivelTierra` debe coincidir con el rim de esta imagen (≈ 0.64
/// en un canvas con relación 1 : 2.2).
class MacetaImagen extends StatelessWidget {
  /// Periodo del día actual — define el filtro de color.
  final PeriodoDia periodo;

  const MacetaImagen({super.key, required this.periodo});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // La imagen es 1:1; ocupa la franja inferior cuadrada del canvas.
        // Si el canvas es más alto que ancho, dejamos espacio arriba para
        // el jazmín; si fuera más ancho, la imagen se centra.
        final tamImagen = w.clamp(0.0, h);
        final imagenTop = h - tamImagen;

        return Stack(
          children: [
            // Sombra de contacto sobre la mesa (opcional pero ayuda).
            Positioned(
              left: 0,
              right: 0,
              bottom: -2,
              child: Center(
                child: _SombraContacto(
                  width: tamImagen * 0.55,
                  height: 14,
                  intensidad: periodo.esNoche ? 0.65 : 0.55,
                ),
              ),
            ),
            // Imagen de la maceta con el filtro de ambiente.
            Positioned(
              left: (w - tamImagen) / 2,
              top: imagenTop,
              width: tamImagen,
              height: tamImagen,
              child: ColorFiltered(
                colorFilter: FiltrosAmbiente.maceta(periodo),
                child: Image.asset(
                  'assets/images/maceta.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB87642).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'maceta.png\nno encontrada',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 10),
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
  }
}

/// Sombra elíptica difuminada que se dibuja justo bajo la maceta para
/// integrarla con la mesa de la imagen de fondo.
class _SombraContacto extends StatelessWidget {
  final double width;
  final double height;
  final double intensidad;

  const _SombraContacto({
    required this.width,
    required this.height,
    required this.intensidad,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SombraContactoPainter(intensidad: intensidad),
    );
  }
}

class _SombraContactoPainter extends CustomPainter {
  final double intensidad;

  _SombraContactoPainter({required this.intensidad});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width,
        height: size.height,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: intensidad)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _SombraContactoPainter old) =>
      old.intensidad != intensidad;
}
