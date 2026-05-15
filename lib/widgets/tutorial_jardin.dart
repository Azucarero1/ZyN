import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/estado_jardin.dart';
import '../core/theme.dart';

/// Diálogo de bienvenida que se muestra la **primera vez** que la
/// usuaria entra al Jardín del Amor. Explica qué hacer y cómo funciona
/// el sistema de jazmines + ramo.
///
/// Se persiste con [EstadoJardin.marcarTutorialVisto] al cerrarlo, así
/// solo aparece una vez.
class TutorialJardin extends StatelessWidget {
  const TutorialJardin({super.key});

  /// Comprueba si el tutorial debe mostrarse y, en su caso, lo abre
  /// como un overlay modal sobre la pantalla del jardín.
  static Future<void> mostrarSiHaceFalta(BuildContext context) async {
    if (EstadoJardin.tutorialVisto) return;
    // Espera un frame para asegurarse de que el contexto esté listo.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const TutorialJardin(),
      transitionBuilder: (_, anim, __, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curva,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curva),
            child: child,
          ),
        );
      },
    );
    await EstadoJardin.marcarTutorialVisto();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.granateProfundo,
                AppColors.granateNoche,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.oro.withValues(alpha: 0.6),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD166).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Text(
                'Tu Jardín del Amor',
                textAlign: TextAlign.center,
                style: GoogleFonts.greatVibes(
                  fontSize: 42,
                  color: AppColors.oroClaro,
                  height: 0.95,
                  shadows: [
                    Shadow(
                      color: AppColors.granateNoche,
                      blurRadius: 8,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Filete dorado
              Container(
                width: 90,
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.oro,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mensaje principal
              Text(
                'Bienvenida a un rincón que te he hecho con mucho amor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppColors.oroClaro,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Instrucciones en filas
              const _PasoTutorial(
                numero: '1',
                icono: Icons.water_drop_rounded,
                texto:
                    'Toca la gota cada día para regar tu jazmín. Cada riego le quita 10 % de sed.',
              ),
              const SizedBox(height: 12),
              const _PasoTutorial(
                numero: '2',
                icono: Icons.eco_rounded,
                texto:
                    'Riégalo todos los días durante 14 días seguidos para que florezca.',
              ),
              const SizedBox(height: 12),
              const _PasoTutorial(
                numero: '3',
                icono: Icons.local_florist_rounded,
                texto:
                    'Cuando esté en plena flor, recógelo y se sumará a tu ramo. Reúne 5 jazmines.',
              ),
              const SizedBox(height: 12),
              const _PasoTutorial(
                numero: '4',
                icono: Icons.cake_rounded,
                texto:
                    'Cuando el ramo esté completo, te tendré una sorpresa lista para tu cumpleaños.',
              ),

              const SizedBox(height: 22),

              // Detalle "Para mi amor"
              Text(
                'Para mi amor 💕',
                textAlign: TextAlign.center,
                style: GoogleFonts.greatVibes(
                  fontSize: 22,
                  color: AppColors.oroClaro.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 16),

              // Botón "Empezar"
              Material(
                color: const Color(0xFFE8C868),
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.granateNoche,
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      'Empezar',
                      style: GoogleFonts.greatVibes(
                        fontSize: 26,
                        color: AppColors.granateNoche,
                        fontWeight: FontWeight.w500,
                        height: 0.95,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila del tutorial con número, icono y texto explicativo.
class _PasoTutorial extends StatelessWidget {
  final String numero;
  final IconData icono;
  final String texto;

  const _PasoTutorial({
    required this.numero,
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Círculo con número
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.oro.withValues(alpha: 0.85),
            border: Border.all(
              color: AppColors.oroClaro,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              numero,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.granateNoche,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icono, color: AppColors.oroClaro, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14.5,
              color: AppColors.oroClaro,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
