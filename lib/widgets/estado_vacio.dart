import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Mensaje vintage que se muestra cuando la galería todavía está vacía.
class EstadoVacioVintage extends StatelessWidget {
  final double factorEscala;

  const EstadoVacioVintage({super.key, required this.factorEscala});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _LineaDecorativa(ancho: 120),
              const SizedBox(height: 40),
              const _IconoCamaraAnimado(),
              const SizedBox(height: 40),
              Text(
                'Álbum de Recuerdos',
                textAlign: TextAlign.center,
                style: GoogleFonts.greatVibes(
                  fontSize: 36,
                  color: AppColors.granate,
                  shadows: [
                    Shadow(
                      color: AppColors.oro.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _LineaDecorativa(ancho: 60, alto: 2),
              const SizedBox(height: 25),
              Text(
                'Tu colección está esperando ser llenada con momentos especiales',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  color: AppColors.granate.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 35),
              _Instruccion(factorEscala: factorEscala),
              const SizedBox(height: 40),
              const _LineaDecorativa(ancho: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineaDecorativa extends StatelessWidget {
  final double ancho;
  final double alto;

  const _LineaDecorativa({required this.ancho, this.alto = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.oro.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _IconoCamaraAnimado extends StatelessWidget {
  const _IconoCamaraAnimado();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.granate.withOpacity(0.8),
                  AppColors.granate,
                  AppColors.granate.withOpacity(0.9),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.oro, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.oro.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 55,
              color: AppColors.oro,
            ),
          ),
        ),
      ),
    );
  }
}

class _Instruccion extends StatelessWidget {
  final double factorEscala;

  const _Instruccion({required this.factorEscala});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        border: Border.all(color: AppColors.oro.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined,
              color: AppColors.oro, size: 24 * factorEscala),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Toca el botón de cámara para añadir tus fotos y videos',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15,
                color: AppColors.granate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
