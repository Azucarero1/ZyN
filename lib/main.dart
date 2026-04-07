// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/notificaciones.dart';
import 'core/estado_global.dart'; 
import 'screens/splash_screen.dart';
import 'screens/galeria_screen.dart'; // Importa tu galería

void main() async {
  // 1. Aseguramos que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Iniciamos la app con el Splash directamente
  runApp(RegaloZairaApp());
}

class RegaloZairaApp extends StatelessWidget {
  // Función que carga todo lo pesado
  Future<void> _prepararApp() async {
    await inicializarNotificaciones();
    await EstadoGlobal.inicializar();
    // Aquí puedes meter un delay artificial de 1 o 2 segundos 
    // SOLO para que se vea tu corazón hermoso, pero ya cargando datos.
    await Future.delayed(Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: EstadoGlobal.escalaApp,
      builder: (context, escala, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Color(0xFF6B2A2A),
            textTheme: GoogleFonts.cormorantGaramondTextTheme(Theme.of(context).textTheme),
          ),
          // Usamos un FutureBuilder para que el Splash sepa CUÁNDO quitarse
          home: FutureBuilder(
            future: _prepararApp(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return PantallaGaleriaVintage(); // Al terminar, va a la galería
              }
              return PantallaCargaSplash(); // Mientras carga, muestra el corazón
            },
          ),
        );
      },
    );
  }
}