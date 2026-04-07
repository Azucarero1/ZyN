import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';

final FlutterLocalNotificationsPlugin notificacionesPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationDetails detallesAndroid = AndroidNotificationDetails(
  'canal_amor', 'Mensajes de Amor',
  importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher',
);
const NotificationDetails detallesNotificacion = NotificationDetails(android: detallesAndroid);

Future<void> inicializarNotificaciones() async {
  if (kIsWeb) return; 

  const AndroidInitializationSettings configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings configtotal = InitializationSettings(android: configAndroid);
  
  await notificacionesPlugin.initialize(settings: configtotal);

  final List<String> mensajes = [
    "Recuerda que te amo muchísimo ❤️",
    "Eres mi pensamiento favorito del día ✨",
    "Contando los segundos para volver a abrazarte 🥰",
    "Mi vida es mejor desde que estás en ella 💖",
    "Aunque estemos lejos, mi corazón está contigo 🌍❤️",
    "Cada día que pasa es un día menos para vernos ⏳💕",
    "Sonrío solo de pensar en ti... Te amo 😊❤️"
  ];

  String mensajeAleatorio = mensajes[Random().nextInt(mensajes.length)];
  
  await notificacionesPlugin.show(
    id: 0, title: '¡Hola mi niña! 💌', body: mensajeAleatorio, notificationDetails: detallesNotificacion
  );
}