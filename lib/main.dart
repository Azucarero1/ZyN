import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/estado_global.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Evita descargas de fuentes en runtime; usa solo las fuentes empaquetadas
  // en assets/fonts/ para que la app funcione sin conexión a internet.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const RegaloZynApp());
}

class RegaloZynApp extends StatelessWidget {
  const RegaloZynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZyN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.granate,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.granate,
          primary: AppColors.granate,
          secondary: AppColors.oro,
        ),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      // Builder global: aplica el factor de escala como `textScaler` a todo
      // el árbol de widgets, de forma reactiva. Esto hace que cambiar el
      // slider de "Tamaño de la galería" actualice el tamaño en tiempo real
      // en TODA la app sin tener que multiplicar manualmente cada `fontSize`.
      builder: (context, child) {
        return ValueListenableBuilder<double>(
          valueListenable: EstadoGlobal.escalaApp,
          builder: (_, escala, __) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(escala)),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
      home: const PantallaCargaSplash(),
    );
  }
}
