import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EstadoGlobal {
  // Controla el tamaño de la interfaz
  static final ValueNotifier<double> escalaApp = ValueNotifier<double>(1.0);

  // LA LISTA MAESTRA: Inicia vacía, el usuario añade sus propios recuerdos
  static final List<Map<String, String>> misRecuerdos = [];

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