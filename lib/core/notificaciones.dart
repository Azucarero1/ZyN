import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

/// IDs reservados para notificaciones específicas (evita choques).
class IdsNotificacion {
  IdsNotificacion._();
  static const int bienvenida = 0;
  static const int unaSemana = 1;
  static const int unDia = 2;
}

/// Inicializa el plugin de notificaciones. No muestra nada por sí sola;
/// para enviar un mensaje hay que llamar a [enviarMensajeAleatorio].
Future<void> inicializarNotificaciones() async {
  if (kIsWeb) return;

  const configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const configTotal = InitializationSettings(android: configAndroid);

  // En la versión 21.x del paquete `initialize` y `show` usan parámetros
  // exclusivamente con nombre.
  await notificacionesPlugin.initialize(settings: configTotal);

  // En Android 13+ hay que pedir permiso explícitamente.
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
