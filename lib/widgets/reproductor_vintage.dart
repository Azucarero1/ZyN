import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'reproductor_vinilo.dart';

/// Pequeño "radio vintage" anclado en la parte inferior de la galería.
/// Toca el display para abrir el reproductor de vinilo en pantalla completa.
class ReproductorRadioVintage extends StatelessWidget {
  final double factorEscala;
  final ValueNotifier<int> indiceCancionNotifier;
  final ValueNotifier<bool> estaReproduciendoNotifier;
  final ValueNotifier<bool> modoAleatorioNotifier;
  final ValueNotifier<bool> modoRepetirNotifier;
  final List<String> miMusica;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleAleatorio;
  final VoidCallback onToggleRepetir;
  final AudioPlayer reproductor;

  const ReproductorRadioVintage({
    super.key,
    required this.factorEscala,
    required this.indiceCancionNotifier,
    required this.estaReproduciendoNotifier,
    required this.modoAleatorioNotifier,
    required this.modoRepetirNotifier,
    required this.miMusica,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleAleatorio,
    required this.onToggleRepetir,
    required this.reproductor,
  });

  String _nombreCancion(String ruta) =>
      ruta.split('/').last.replaceAll('.mp3', '').replaceAll('_', ' ');

  void _abrirVinilo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => ReproductorVinilo(
        estaReproduciendoNotifier: estaReproduciendoNotifier,
        indiceCancionNotifier: indiceCancionNotifier,
        onPlayPause: onPlayPause,
        onNext: onNext,
        onPrevious: onPrevious,
        miMusica: miMusica,
        reproductor: reproductor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * factorEscala, vertical: 12),
      padding: EdgeInsets.all(16 * factorEscala),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A2525), AppColors.granate, Color(0xFF4A1F1F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.oro.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _abrirVinilo(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * factorEscala,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.granateProfundo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.oro.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note_outlined,
                      color: AppColors.oro, size: 18 * factorEscala),
                  SizedBox(width: 12 * factorEscala),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: indiceCancionNotifier,
                      builder: (_, indice, __) =>
                          ValueListenableBuilder<bool>(
                        valueListenable: estaReproduciendoNotifier,
                        builder: (_, reproduciendo, __) => Text(
                          reproduciendo
                              ? _nombreCancion(miMusica[indice])
                              : 'Presiona Play',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            color: AppColors.oroClaro,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * factorEscala),
                  Icon(Icons.music_note_outlined,
                      color: AppColors.oro, size: 18 * factorEscala),
                ],
              ),
            ),
          ),
          SizedBox(height: 16 * factorEscala),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Knob(
                icon: Icons.shuffle_rounded,
                notifier: modoAleatorioNotifier,
                onTap: onToggleAleatorio,
                size: 36 * factorEscala,
              ),
              SizedBox(width: 20 * factorEscala),
              _RoundBtn(
                icon: Icons.skip_previous_rounded,
                onTap: onPrevious,
                size: 48 * factorEscala,
              ),
              SizedBox(width: 16 * factorEscala),
              ValueListenableBuilder<bool>(
                valueListenable: estaReproduciendoNotifier,
                builder: (_, reproduciendo, __) => GestureDetector(
                  // Siempre delegamos en onPlayPause; éste decide si
                  // hay que arrancar desde cero, reanudar o pausar.
                  onTap: onPlayPause,
                  child: Container(
                    width: 64 * factorEscala,
                    height: 64 * factorEscala,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.oro,
                          AppColors.oroBrillante,
                          AppColors.oro,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF4A1F1F), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      reproduciendo
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF4A1F1F),
                      size: 36 * factorEscala,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16 * factorEscala),
              _RoundBtn(
                icon: Icons.skip_next_rounded,
                onTap: onNext,
                size: 48 * factorEscala,
              ),
              SizedBox(width: 20 * factorEscala),
              _Knob(
                icon: Icons.repeat_rounded,
                notifier: modoRepetirNotifier,
                onTap: onToggleRepetir,
                size: 36 * factorEscala,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _RoundBtn({required this.icon, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.granate.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.oro.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.oro, size: size * 0.5),
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  final IconData icon;
  final ValueNotifier<bool> notifier;
  final VoidCallback onTap;
  final double size;

  const _Knob({
    required this.icon,
    required this.notifier,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, activo, __) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: activo
                  ? const [AppColors.oro, AppColors.oroClaro]
                  : const [AppColors.granate, Color(0xFF4A1F1F)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.oro.withOpacity(activo ? 1 : 0.3),
              width: 2,
            ),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: AppColors.oro.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: activo
                ? const Color(0xFF4A1F1F)
                : AppColors.oro.withOpacity(0.6),
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}
