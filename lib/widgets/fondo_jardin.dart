import 'dart:async';

import 'package:flutter/material.dart';

/// Hora "efectiva" que usan los widgets del jardín — puede ser la hora
/// real del dispositivo o una **simulada** desde el panel de admin para
/// previsualizar día/atardecer/noche sin esperar.
///
/// `hora` es un [ValueNotifier<int>] al que se suscriben los widgets
/// (FondoJardinBotanico, MacetaImagen, etc.); cambia de valor cuando
/// pasa un minuto del reloj real Y cuando se aplica/limpia un override.
///
/// ⚠ Junto con los métodos `admin*`, eliminar antes de la versión final.
class HoraEfectiva {
  HoraEfectiva._();

  /// Hora actual efectiva (0–23). Override si hay; reloj real si no.
  static final ValueNotifier<int> hora = _crear();

  /// Override actual (null = automática según reloj).
  static int? _override;

  static ValueNotifier<int> _crear() {
    final n = ValueNotifier<int>(DateTime.now().hour);
    // Timer perpetuo: cada minuto refresca SOLO si no hay override activo.
    Timer.periodic(const Duration(minutes: 1), (_) {
      if (_override == null) {
        final ahora = DateTime.now().hour;
        if (ahora != n.value) n.value = ahora;
      }
    });
    return n;
  }

  /// Override actual en horas (null = sin override).
  static int? get override => _override;

  /// Fija un override (0–23) que ignora el reloj real.
  static void establecerOverride(int h) {
    _override = h.clamp(0, 23);
    hora.value = _override!;
  }

  /// Limpia el override y vuelve a la hora real del dispositivo.
  static void limpiar() {
    _override = null;
    hora.value = DateTime.now().hour;
  }
}

/// Periodos del día, calculados según la hora real del dispositivo.
/// Compartido entre fondo, maceta, jazmín y luciérnagas para que toda
/// la escena respire la misma luz.
enum PeriodoDia {
  dia,
  atardecer,
  noche;

  /// Calcula el periodo a partir de una hora (0-23).
  ///   07–16 → día
  ///   05–06 y 17–19 → atardecer (ambos lucen igual cromáticamente)
  ///   20–04 → noche
  static PeriodoDia deHora(int hora) {
    if (hora >= 7 && hora < 17) return PeriodoDia.dia;
    if ((hora >= 5 && hora < 7) || (hora >= 17 && hora < 20)) {
      return PeriodoDia.atardecer;
    }
    return PeriodoDia.noche;
  }

  /// Periodo correspondiente al instante actual.
  static PeriodoDia actual() => deHora(DateTime.now().hour);

  bool get esNoche => this == PeriodoDia.noche;
}

/// Filtros de color que aplicamos a los elementos del jardín para que
/// "respiren" la luz del periodo del día. La idea es que la maceta, el
/// jazmín y el fondo compartan el mismo tinte ambiente — exactamente
/// como ocurre en la realidad.
class FiltrosAmbiente {
  FiltrosAmbiente._();

  /// Filtro fuerte de atenuación + tono ambiente para el FONDO.
  /// El fondo debe ceder protagonismo, así que se desatura ~50 % y
  /// se oscurece ~35 %, con un sesgo cromático según el periodo.
  static const ColorFilter _fondoDia = ColorFilter.matrix(<double>[
    0.45, 0.18, 0.07, 0, 0,
    0.18, 0.45, 0.07, 0, 0,
    0.18, 0.18, 0.34, 0, 0,
    0,    0,    0,    1, 0,
  ]);

  static const ColorFilter _fondoAtardecer = ColorFilter.matrix(<double>[
    0.55, 0.20, 0.05, 0, 0,    // R amplificado
    0.18, 0.42, 0.05, 0, 0,    // G normal
    0.10, 0.10, 0.28, 0, -4,   // B reducido (warm bias)
    0,    0,    0,    1, 0,
  ]);

  static const ColorFilter _fondoNoche = ColorFilter.matrix(<double>[
    0.30, 0.10, 0.05, 0, 0,    // R bajo
    0.10, 0.32, 0.10, 0, 0,    // G bajo
    0.18, 0.18, 0.45, 0, 0,    // B preservado (cool bias)
    0,    0,    0,    1, 0,
  ]);

  /// Filtro para la MACETA. Debe quedar a una luminosidad **similar al
  /// fondo** (sólo un poco más viva para que mantenga el protagonismo).
  /// Las matrices se han diseñado para que la suma de cada fila esté
  /// ~10 puntos por encima de la del filtro del fondo correspondiente.
  static const ColorFilter _macetaDia = ColorFilter.matrix(<double>[
    0.65, 0.18, 0.07, 0, 0,    // R ≈ 90 % brillo, ligero desaturado
    0.18, 0.62, 0.07, 0, 0,    // G ≈ 87 %
    0.10, 0.18, 0.55, 0, 0,    // B ≈ 83 %
    0,    0,    0,    1, 0,
  ]);

  static const ColorFilter _macetaAtardecer = ColorFilter.matrix(<double>[
    0.85, 0.18, 0.00, 0, 0,    // R amplificado (luz dorada)
    0.10, 0.62, 0.05, 0, -3,   // G normal
    0.00, 0.05, 0.32, 0, -8,   // B muy reducido (calor)
    0,    0,    0,    1, 0,
  ]);

  static const ColorFilter _macetaNoche = ColorFilter.matrix(<double>[
    0.30, 0.10, 0.05, 0, 0,    // R muy bajo
    0.10, 0.32, 0.10, 0, 0,    // G muy bajo
    0.20, 0.20, 0.55, 0, 0,    // B preservado (luna)
    0,    0,    0,    1, 0,
  ]);

  /// Devuelve el filtro de FONDO para el periodo dado.
  static ColorFilter fondo(PeriodoDia p) => switch (p) {
        PeriodoDia.dia => _fondoDia,
        PeriodoDia.atardecer => _fondoAtardecer,
        PeriodoDia.noche => _fondoNoche,
      };

  /// Devuelve el filtro de la MACETA para el periodo dado.
  static ColorFilter maceta(PeriodoDia p) => switch (p) {
        PeriodoDia.dia => _macetaDia,
        PeriodoDia.atardecer => _macetaAtardecer,
        PeriodoDia.noche => _macetaNoche,
      };

  /// Color tinte para superponer al jazmín procedural según el periodo.
  /// Devuelve un `Color` que `JazminPainter` interpola con sus colores
  /// base (verde, blanco, amarillo) para dar el aire del momento.
  static Color tinteJazmin(PeriodoDia p) => switch (p) {
        PeriodoDia.dia => Colors.transparent,
        PeriodoDia.atardecer => const Color(0xFFC08850),
        PeriodoDia.noche => const Color(0xFF1A2E50),
      };

  /// Intensidad (0–1) con la que se mezcla el tinte sobre el jazmín.
  static double intensidadTinteJazmin(PeriodoDia p) => switch (p) {
        PeriodoDia.dia => 0.0,
        PeriodoDia.atardecer => 0.20,
        PeriodoDia.noche => 0.45,
      };
}

/// Fondo del Jardín del Amor: imagen de jardín botánico victoriano que
/// cambia automáticamente entre **día**, **atardecer** y **noche** según
/// la hora real del dispositivo.
///
/// Las tres imágenes muestran exactamente la misma composición (mesita
/// vintage en primer plano, invernadero al fondo, vegetación tropical
/// alrededor) — solo cambia la iluminación. Esto hace que la transición
/// día/noche resulte natural y que la maceta encaje siempre en la mesa
/// que aparece en el centro de la imagen.
///
/// Recursos:
///  · `assets/images/jardin_dia.jpg`        (cielo azul, ~ 7-17 h)
///  · `assets/images/jardin_atardecer.jpg`  (rosa/naranja, ~ 5-7 h y 17-20 h)
///  · `assets/images/jardin_noche.jpg`      (oscuro con luna, ~ 20-5 h)
class FondoJardinBotanico extends StatelessWidget {
  const FondoJardinBotanico({super.key});

  /// Devuelve la imagen apropiada para la hora actual.
  ///
  ///   05–06 h  → atardecer (amanecer cromáticamente similar)
  ///   07–16 h  → día
  ///   17–19 h  → atardecer
  ///   20–04 h  → noche
  static String _imagenSegunHora(int hora) {
    if (hora >= 7 && hora < 17) {
      return 'assets/images/jardin_dia.jpg';
    }
    if ((hora >= 5 && hora < 7) || (hora >= 17 && hora < 20)) {
      return 'assets/images/jardin_atardecer.jpg';
    }
    return 'assets/images/jardin_noche.jpg';
  }

  /// Color de fallback acorde al periodo del día, por si la imagen aún
  /// no está empaquetada en assets.
  static Color _colorFallback(int hora) {
    if (hora >= 7 && hora < 17) return const Color(0xFF3A4A38);   // verde día
    if ((hora >= 5 && hora < 7) || (hora >= 17 && hora < 20)) {
      return const Color(0xFF6E3A52); // dusk granate-rosado
    }
    return const Color(0xFF0A1428); // azul noche
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: HoraEfectiva.hora,
      builder: (_, hora, __) {
        final periodo = PeriodoDia.deHora(hora);
        final asset = _imagenSegunHora(hora);
        final fallback = _colorFallback(hora);
        // Transición suave entre escenas (1.2 s) cuando cambia la hora.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 1200),
          child: SizedBox.expand(
            key: ValueKey(asset),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Imagen del fondo con el filtro ambiente del periodo.
                //    Cada periodo del día tiene su propio sesgo cromático.
                ColorFiltered(
                  colorFilter: FiltrosAmbiente.fondo(periodo),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [fallback, Colors.black],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 2. Velo extra muy sutil para profundidad atmosférica.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
