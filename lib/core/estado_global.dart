import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EstadoGlobal {
  // Controla el tamaño de la interfaz
  static final ValueNotifier<double> escalaApp = ValueNotifier<double>(1.0);

  // LA LISTA MAESTRA: Ahora vive aquí para que el Splash Screen la pueda leer
  static final List<Map<String, String>> misRecuerdos = [
    {"tipo": "video", "archivo": "assets/images/video1.mp4"},
    {"tipo": "foto", "archivo": "assets/images/foto1.jpg"},
    {"tipo": "foto", "archivo": "assets/images/foto2.jpg"},
    {"tipo": "foto", "archivo": "assets/images/foto3.jpg"},
    {"tipo": "video", "archivo": "assets/images/video2.mp4"},
    {"tipo": "foto", "archivo": "assets/images/foto4.jpg"},
    {"tipo": "foto", "archivo": "assets/images/foto5.jpg"},
    {"tipo": "video", "archivo": "assets/images/video3.mp4"},
    {"tipo": "foto", "archivo": "assets/images/foto6.jpg"},
    {"tipo": "foto", "archivo": "assets/images/foto7.jpg"},
    {"tipo": "foto", "archivo": "assets/images/foto8.jpg"},
    {"tipo": "video", "archivo": "assets/images/video4.mp4"},
    {"tipo": "foto", "archivo": "assets/images/foto10.jpg"}
  ];

  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    escalaApp.value = prefs.getDouble('escala_app_zyn') ?? 1.0;
  }

  static Future<void> cambiarEscala(double nuevaEscala) async {
    escalaApp.value = nuevaEscala;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('escala_app_zyn', nuevaEscala);
  }
}