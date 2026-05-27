import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Plugin global de notificaciones locales.
final FlutterLocalNotificationsPlugin notificacionesPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationDetails _detallesAndroid = AndroidNotificationDetails(
  'canal_amor',
  'Mensajes de Amor',
  channelDescription: 'Notificaciones románticas y recordatorios.',
  importance: Importance.max,
  priority: Priority.high,
  icon: '@mipmap/ic_launcher',
);

const NotificationDetails detallesNotificacion =
    NotificationDetails(android: _detallesAndroid);

const List<String> _mensajesAmor = [
  'Recuerda que te amo muchísimo ❤️',
  'Eres mi pensamiento favorito del día ✨',
  'Contando los segundos para volver a abrazarte 🥰',
  'Mi vida es mejor desde que estás en ella 💖',
  'Aunque estemos lejos, mi corazón está contigo 🌍❤️',
  'Cada día que pasa es un día menos para vernos ⏳💕',
  'Sonrío solo de pensar en ti... Te amo 😊❤️',
];

/// Frases rotatorias usadas en el recordatorio diario de riego. La que
/// se muestre el día concreto depende del día del año (rotación estable).
const List<String> _mensajesRiego = [
  'Tu jazmín te espera amor — riégalo un momento 💧',
  'No te olvides de regar tu jazmín hoy 🌸',
  'Tu pequeña planta necesita un poco de agua 💧✨',
  'Un toquecito al jazmín antes de dormir 🌙',
  'Riega tu jazmín mi vida — está esperándote 💕',
  'Tu jazmín del jardín no se riega solo 😊💧',
  'Un riego diario hace florecer recuerdos 🌸',
];

/// IDs reservados para notificaciones específicas (evita choques).
class IdsNotificacion {
  IdsNotificacion._();
  static const int bienvenida = 0;
  static const int unaSemana = 1;
  static const int unDia = 2;
  // Recordatorio diario de riego (a la hora configurada).
  static const int riegoDiario = 100;
}

/// Inicializa el plugin de notificaciones, su timezone local y solicita
/// permiso al usuario. **Robusto**: ningún fallo aquí impide arrancar la
/// app — si los permisos son denegados, las notificaciones simplemente
/// no se entregan, pero la app sigue funcionando con normalidad.
Future<void> inicializarNotificaciones() async {
  if (kIsWeb) return;

  try {
    // 1. Cargar la base de timezones (necesario para zonedSchedule).
    tz.initializeTimeZones();

    const configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const configTotal = InitializationSettings(android: configAndroid);
    await notificacionesPlugin.initialize(settings: configTotal);
  } catch (e) {
    debugPrint('Fallo al inicializar notificaciones: $e');
    return; // No tiene sentido seguir si la inicialización falló.
  }

  // 2. Permiso de notificaciones (Android 13+). Si la usuaria lo
  //    rechaza, no pasa nada — la app sigue funcionando sin
  //    notificaciones. NO pedimos permiso de "alarmas exactas" porque
  //    nuestro recordatorio usa el modo inexacto (no lo necesita).
  try {
    await notificacionesPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  } catch (e) {
    debugPrint('Permiso de notificaciones no concedido: $e');
  }
}

/// Envía una notificación con un mensaje romántico aleatorio.
/// Útil como saludo de bienvenida tras la primera apertura del día.
Future<void> enviarMensajeAleatorio() async {
  if (kIsWeb) return;
  final mensaje = _mensajesAmor[Random().nextInt(_mensajesAmor.length)];
  try {
    await notificacionesPlugin.show(
      id: IdsNotificacion.bienvenida,
      title: '¡Hola mi niña! 💌',
      body: mensaje,
      notificationDetails: detallesNotificacion,
    );
  } catch (e) {
    debugPrint('No pude enviar la notificación de bienvenida: $e');
  }
}

/// Muestra una notificación inmediata con título y cuerpo personalizados.
Future<void> notificar({
  required int id,
  required String titulo,
  required String cuerpo,
}) async {
  if (kIsWeb) return;
  try {
    await notificacionesPlugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: detallesNotificacion,
    );
  } catch (e) {
    debugPrint('No pude enviar la notificación ($id): $e');
  }
}

/// Programa el recordatorio **diario** para regar la planta.
///
/// La notificación se dispara cada día a la hora indicada (por defecto
/// 20:00). Se reprograma automáticamente al día siguiente porque usamos
/// `matchDateTimeComponents: DateTimeComponents.time`.
///
/// Si ya había una programada con el mismo ID, se cancela antes para
/// evitar duplicados. Llamar a esta función:
///  · Al arrancar la app (en el splash) para asegurar que está activa.
///  · Cada vez que la usuaria cambie la hora desde Ajustes.
///  · Tras regar la planta, para reflejar la nueva fecha de recordatorio.
Future<void> programarRiegoDiario({int hora = 20, int minuto = 0}) async {
  if (kIsWeb) return;
  try {
    await notificacionesPlugin.cancel(id: IdsNotificacion.riegoDiario);

    final ahora = tz.TZDateTime.now(tz.local);
    var cuando = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora,
      minuto,
    );
    // Si la hora ya pasó hoy, programar para mañana.
    if (cuando.isBefore(ahora)) {
      cuando = cuando.add(const Duration(days: 1));
    }

    // Día del año (1-366) para escoger un mensaje rotatorio estable.
    final inicioAnio = DateTime(ahora.year);
    final diaDelAnio =
        DateTime(ahora.year, ahora.month, ahora.day).difference(inicioAnio).inDays + 1;
    final mensaje =
        _mensajesRiego[diaDelAnio % _mensajesRiego.length];

    await notificacionesPlugin.zonedSchedule(
      id: IdsNotificacion.riegoDiario,
      title: '🌸 Tu jazmín',
      body: mensaje,
      scheduledDate: cuando,
      notificationDetails: detallesNotificacion,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Repetir cada día a la misma hora — gracias a este flag, el
      // sistema reprograma sola la siguiente notificación al disparar.
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint(
        'Recordatorio de riego programado para ${cuando.hour}:${cuando.minute.toString().padLeft(2, "0")} (diariamente).');
  } catch (e) {
    debugPrint('No pude programar el recordatorio de riego: $e');
  }
}

/// Cancela el recordatorio diario de riego (al desactivar la app o
/// para reprogramar a otra hora).
Future<void> cancelarRiegoDiario() async {
  if (kIsWeb) return;
  try {
    await notificacionesPlugin.cancel(id: IdsNotificacion.riegoDiario);
  } catch (_) {}
}
