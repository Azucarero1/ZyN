import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado del Jardín del Amor.
///
/// Cada jazmín requiere [diasParaFlorecer] aperturas consecutivas para
/// florecer. Al completarse, se recolecta en el ramo y comienza un jazmín
/// nuevo. Si pasan días sin abrir la app, el jazmín se marchita
/// progresivamente (3 días sin riego = la flor muere y debe replantarse,
/// pero las flores ya recolectadas en el ramo permanecen).
///
/// Cumpleaños objetivo: 24 de julio. Con 5 jazmines × 14 días = 70 días
/// mínimos, dejando un margen de 4 días para imprevistos.
class EstadoJardin {
  EstadoJardin._();

  /// Días consecutivos necesarios para que un jazmín florezca completamente.
  static const int diasParaFlorecer = 14;

  /// Total de jazmines que completan el ramo.
  static const int floresParaRamo = 5;

  /// Cumpleaños objetivo (para el contador).
  static final DateTime cumpleanos = DateTime(2026, 7, 24);

  static const _kUltimaApertura = 'jardin_ultima_apertura';
  static const _kDiasRacha = 'jardin_dias_racha';
  static const _kFloresRamo = 'jardin_flores_ramo';
  static const _kHoraNotif = 'jardin_hora_notif';
  static const _kRamoCelebrado = 'jardin_ramo_celebrado';
  // Marchitez ahora se persiste — cada riego (-10 %) y cada día sin
  // regar (+33 %) afecta este valor de forma duradera.
  static const _kMarchitez = 'jardin_marchitez_valor';
  static const _kFechaMarchitez = 'jardin_marchitez_fecha';
  // True una vez que se mostró el tutorial inicial.
  static const _kTutorialVisto = 'jardin_tutorial_visto';

  /// Marchitez que se añade por cada día sin riego (0.33 → 3 días al
  /// 100 %). Compensa con los -10 % por toque del botón regar.
  static const double _aumentoMarchitezDiario = 0.33;

  /// Días consecutivos del jazmín actual (0 a [diasParaFlorecer]).
  static final ValueNotifier<int> diasRacha = ValueNotifier<int>(0);

  /// Jazmines completados que están en el ramo (0 a [floresParaRamo]).
  static final ValueNotifier<int> floresEnRamo = ValueNotifier<int>(0);

  /// Nivel de marchitamiento actual: 0.0 (sano) a 1.0 (muerto).
  /// Se calcula a partir de los días sin riego.
  static final ValueNotifier<double> marchitez = ValueNotifier<double>(0.0);

  /// Bandera que indica si el ramo recién se completó y aún no se mostró
  /// la celebración (animación + mensaje de cumpleaños).
  static final ValueNotifier<bool> ramoListoParaCelebrar =
      ValueNotifier<bool>(false);

  static SharedPreferences? _prefs;
  static bool _inicializado = false;

  /// Hora del recordatorio diario de riego en formato "HH:mm".
  /// Por defecto 20:00. Configurable desde Ajustes.
  static String get horaNotificacion =>
      _prefs?.getString(_kHoraNotif) ?? '20:00';

  static Future<void> guardarHoraNotificacion(String horaHHmm) async {
    await _prefs?.setString(_kHoraNotif, horaHHmm);
  }

  /// Carga el estado persistido. Idempotente.
  /// True si la planta ya se regó hoy. Mientras esté true, la UI oculta
  /// el botón "Regar" y deshabilita los nuevos riegos del día.
  static final ValueNotifier<bool> regadaHoy = ValueNotifier<bool>(false);

  static Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    _prefs = await SharedPreferences.getInstance();
    diasRacha.value = _prefs!.getInt(_kDiasRacha) ?? 0;
    floresEnRamo.value = _prefs!.getInt(_kFloresRamo) ?? 0;
    // Marchitez persistida — cargar el valor guardado en lugar de
    // recalcularlo desde cero.
    marchitez.value = _prefs!.getDouble(_kMarchitez) ?? 0.0;
    await _acumularMarchitezPorDias();
    _actualizarRegadaHoy();
  }

  /// Registra una apertura de la app. Ya **no avanza la racha** —
  /// solo aplica la acumulación diaria de marchitez (cada día sin
  /// regar suma +33 %) y comprueba si la planta ya fue regada hoy.
  /// La racha avanza únicamente con [regarPlanta].
  static Future<void> registrarApertura() async {
    await inicializar();
    await _acumularMarchitezPorDias();
    _actualizarRegadaHoy();
  }

  /// Suma marchitez por cada día que ha pasado desde la última
  /// "acumulación". Se ejecuta al cargar el estado y al abrir la app.
  /// Marchitez es **persistente** — los efectos de tocar el botón
  /// regar (-10 %) sobreviven entre sesiones.
  static Future<void> _acumularMarchitezPorDias() async {
    final hoy = _hoy();
    final ultima = _fechaMarchitez();

    if (ultima == null) {
      // Primer arranque histórico: registrar la fecha sin sumar nada.
      await _prefs?.setString(_kFechaMarchitez, _formatearFecha(hoy));
      await _prefs?.setDouble(_kMarchitez, marchitez.value);
      return;
    }

    final dias = hoy.difference(ultima).inDays;
    if (dias > 0) {
      marchitez.value =
          (marchitez.value + dias * _aumentoMarchitezDiario).clamp(0.0, 1.0);
      await _prefs?.setString(_kFechaMarchitez, _formatearFecha(hoy));
      await _prefs?.setDouble(_kMarchitez, marchitez.value);
    }
  }

  /// Devuelve la fecha del último ajuste de acumulación de marchitez.
  static DateTime? _fechaMarchitez() {
    final s = _prefs?.getString(_kFechaMarchitez);
    if (s == null) return null;
    final partes = s.split('-');
    if (partes.length != 3) return null;
    return DateTime(
      int.tryParse(partes[0]) ?? 2026,
      int.tryParse(partes[1]) ?? 1,
      int.tryParse(partes[2]) ?? 1,
    );
  }

  /// True si la planta murió por descuido (marchitez al 100 %).
  static bool get plantaMuerta => marchitez.value >= 0.999;

  /// Riego: **se puede ejecutar cuantas veces se quiera**.
  ///
  /// Comportamiento según el estado:
  ///  · **Planta muerta** (marchitez ≥ 1.0): REPLANTA un jazmín nuevo
  ///    desde cero (racha = 1, marchitez = 0). Las flores ya recolectadas
  ///    se mantienen.
  ///  · **Planta viva**: resta 0.10 a la marchitez (persiste el cambio).
  ///    Si es el primer riego del día, avanza la racha según el patrón:
  ///      · Primer riego histórico → racha = 1
  ///      · Día consecutivo → racha++
  ///      · Saltó 1-2 días → racha no avanza (penalización)
  ///      · Saltó 3+ días → replantar (racha = 1)
  ///
  /// Devuelve `true` siempre (la acción nunca está bloqueada).
  static Future<bool> regarPlanta() async {
    await inicializar();
    final hoy = _hoy();

    // ━━━ Planta MUERTA → replantar ━━━
    if (plantaMuerta) {
      diasRacha.value = 1;
      marchitez.value = 0.0;
      await _prefs?.setString(_kUltimaApertura, _formatearFecha(hoy));
      await _prefs?.setString(_kFechaMarchitez, _formatearFecha(hoy));
      await _prefs?.setInt(_kDiasRacha, diasRacha.value);
      await _prefs?.setDouble(_kMarchitez, 0.0);
      _actualizarRegadaHoy();
      return true;
    }

    // ━━━ Planta viva: reducir 10 % y persistir ━━━
    marchitez.value = (marchitez.value - 0.10).clamp(0.0, 1.0);
    await _prefs?.setDouble(_kMarchitez, marchitez.value);

    // Lógica de racha (solo el primer riego del día la avanza).
    final ultima = _ultimaApertura();
    if (ultima == null) {
      diasRacha.value = 1;
      await _prefs?.setString(_kUltimaApertura, _formatearFecha(hoy));
      await _prefs?.setInt(_kDiasRacha, diasRacha.value);
    } else {
      final diff = hoy.difference(ultima).inDays;
      if (diff == 0) {
        // Mismo día: solo redujo marchitez; racha no cambia.
      } else if (diff == 1) {
        final nueva = (diasRacha.value + 1).clamp(0, diasParaFlorecer);
        diasRacha.value = nueva;
        await _prefs?.setString(_kUltimaApertura, _formatearFecha(hoy));
        await _prefs?.setInt(_kDiasRacha, diasRacha.value);
      } else if (diff <= 3) {
        await _prefs?.setString(_kUltimaApertura, _formatearFecha(hoy));
      } else {
        // 4+ días sin riego — replantar (la racha vuelve a 1).
        diasRacha.value = 1;
        await _prefs?.setString(_kUltimaApertura, _formatearFecha(hoy));
        await _prefs?.setInt(_kDiasRacha, diasRacha.value);
      }
    }

    _actualizarRegadaHoy();
    return true;
  }

  /// Calcula si el último riego fue hoy.
  static void _actualizarRegadaHoy() {
    final ultima = _ultimaApertura();
    if (ultima == null) {
      regadaHoy.value = false;
      return;
    }
    final hoy = _hoy();
    regadaHoy.value = ultima.year == hoy.year &&
        ultima.month == hoy.month &&
        ultima.day == hoy.day;
  }

  /// Marca la celebración del ramo como vista (no volverá a dispararse).
  static Future<void> marcarRamoCelebrado() async {
    ramoListoParaCelebrar.value = false;
    await _prefs?.setBool(_kRamoCelebrado, true);
  }

  /// True si el jazmín actual está completamente desarrollado y aún
  /// quedan huecos en el ramo. Mientras esté true, la UI muestra el
  /// botón "Recoger flor" en lugar del mensaje habitual.
  static bool get listaParaCosechar =>
      diasRacha.value >= diasParaFlorecer &&
      floresEnRamo.value < floresParaRamo;

  /// Recolecta el jazmín actual: lo añade al ramo y reinicia la racha
  /// para que comience a crecer uno nuevo. Solo funciona si
  /// [listaParaCosechar] es true.
  ///
  /// Si con esta recolección el ramo se completa, marca
  /// [ramoListoParaCelebrar] para que la pantalla dispare la animación
  /// de celebración (a implementar).
  static Future<void> recolectarFlor() async {
    await inicializar();
    if (!listaParaCosechar) return;

    floresEnRamo.value = floresEnRamo.value + 1;
    diasRacha.value = 0;
    marchitez.value = 0.0;

    await _prefs?.setInt(_kDiasRacha, 0);
    await _prefs?.setInt(_kFloresRamo, floresEnRamo.value);

    if (floresEnRamo.value >= floresParaRamo) {
      final yaCelebrado = _prefs?.getBool(_kRamoCelebrado) ?? false;
      if (!yaCelebrado) {
        ramoListoParaCelebrar.value = true;
      }
    }
  }

  static DateTime? _ultimaApertura() {
    final s = _prefs?.getString(_kUltimaApertura);
    if (s == null) return null;
    final partes = s.split('-');
    if (partes.length != 3) return null;
    return DateTime(
      int.tryParse(partes[0]) ?? 2026,
      int.tryParse(partes[1]) ?? 1,
      int.tryParse(partes[2]) ?? 1,
    );
  }

  static DateTime _hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _formatearFecha(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

  /// Días que faltan para el cumpleaños (24 julio).
  static int diasParaCumpleanos() {
    final hoy = _hoy();
    final cum = DateTime(cumpleanos.year, cumpleanos.month, cumpleanos.day);
    return cum.difference(hoy).inDays;
  }

  /// Progreso del jazmín actual de 0.0 a 1.0.
  static double get progresoFlorActual =>
      (diasRacha.value / diasParaFlorecer).clamp(0.0, 1.0);

  /// True si el tutorial inicial ya se mostró (no debe volver a aparecer).
  static bool get tutorialVisto =>
      _prefs?.getBool(_kTutorialVisto) ?? false;

  /// Marca el tutorial inicial como visto. Llamado al cerrar el dialog.
  static Future<void> marcarTutorialVisto() async {
    await _prefs?.setBool(_kTutorialVisto, true);
  }

  /// Estado descriptivo del jazmín ("Brotando", "Floreciendo", etc.).
  /// Si está marchito tiene prioridad sobre el progreso.
  static String estadoJazmin() {
    final m = marchitez.value;
    if (m >= 1.0) return 'Marchito';
    if (m > 0.55) return 'Sediento';
    if (m > 0.0) return 'Necesita agua';

    final p = progresoFlorActual;
    if (p < 0.10) return 'Recién plantado';
    if (p < 0.35) return 'Brotando';
    if (p < 0.60) return 'Creciendo';
    if (p < 0.80) return 'En capullo';
    if (p < 1.0) return 'Floreciendo';
    return 'En plena flor';
  }
}
