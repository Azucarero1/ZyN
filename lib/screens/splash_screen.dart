import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/estado_global.dart';
import 'galeria_screen.dart'; 

class PantallaCargaSplash extends StatefulWidget {
  @override
  _PantallaCargaSplashState createState() => _PantallaCargaSplashState();
}

class _PantallaCargaSplashState extends State<PantallaCargaSplash> with SingleTickerProviderStateMixin {
  // Controlador de animación para el llenado del corazón
  late AnimationController _controller;
  late Animation<double> _animation;
  String _estadoCargaText = "Iniciando...";

  @override
  void initState() {
    super.initState();
    
    // Configuramos la animación (5 segundos para que se llene suavemente)
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Tiempo que tarda en llenarse
    );
    
    // La animación va de 0.0 (vacío) a 1.0 (lleno)
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine, // Llenado fluido y realista
    ));

    // Iniciamos la carga real y la animación al mismo tiempo
    _cargarAppReal();
  }

  @override
  void dispose() {
    _controller.dispose(); // Limpieza de memoria
    super.dispose();
  }

  // AQUÍ ESTÁ LA LÓGICA DE CARGA REAL Y OPTIMIZACIÓN
  Future<void> _cargarAppReal() async {
    // 1. Iniciamos el llenado visual (como si fuera el progreso)
    _controller.forward();

    // 2. Cargamos el estado global (el tamaño de la interfaz)
    await EstadoGlobal.inicializar();
    
    if (mounted) setState(() => _estadoCargaText = "Preparando texturas...");
    
    // 3. Pre-cargamos la imagen de fondo texturizada (¡Tu diseño original!)
    await precacheImage(AssetImage('assets/images/MainBackground.jpg'), context);

    if (mounted) setState(() => _estadoCargaText = "Cargando recuerdos en caché...");
    
    // 4. Leemos la lista global y PRECARGAMOS TODAS LAS FOTOS
    List<Future<void>> tareasDeCarga = [];
    
    for (var recuerdo in EstadoGlobal.misRecuerdos) {
      if (recuerdo["tipo"] == "foto") {
        // Reducimos las imágenes a 300px en la RAM para que la galería vuele
        tareasDeCarga.add(
          precacheImage(ResizeImage(AssetImage(recuerdo["archivo"]!), width: 300), context)
        );
      }
    }

    // 5. EL SPLASH SCREEN SE CONGELA AQUÍ HASTA QUE TODO TERMINE DE CARGAR
    try {
      await Future.wait(tareasDeCarga);
    } catch (e) {
      print("Error precargando algunos assets: $e");
    }

    // 6. Si la carga terminó ANTES que la animación de 5s, aceleramos el final
    if (_controller.value < 0.9) {
      _controller.animateTo(1.0, duration: Duration(milliseconds: 500));
      await Future.delayed(Duration(milliseconds: 500));
    } else {
      // Si la carga tardó más de 5s, esperamos a que termine la animación
      await Future.delayed(Duration(milliseconds: 200));
    }

    // 7. Cuando todo está en la RAM y el corazón lleno, pasamos a la galería fluida
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 1200), // Transición más romántica
          pageBuilder: (_, __, ___) => PantallaGaleriaVintage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores de ZyN
    final Color cT = Color(0xFF6B2A2A); // Granate
    final Color cB = Color(0xFFB89A6A); // Oro

    return Scaffold(
      body: Container(
        // VOLVEMOS A TU FONDO ORIGINAL TEXTURIZADO
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/MainBackground.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 50),
              // TU LOGO ORIGINAL DE ZyN (Granate y Cursivo)
              Text(
                'ZyN', 
                style: GoogleFonts.greatVibes(fontSize: 80, fontWeight: FontWeight.bold, color: cT)
              ),
              Spacer(),
              
              // EL CORAZÓN QUE SE LLENA DE FORMA REALISTA (Animado)
              Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(200, 200), // Tamaño del corazón
                      painter: CorazonLlenandosePainter(
                        progreso: _animation.value,
                        colorRelleno: cT,
                        colorBorde: cB,
                      ),
                    );
                  },
                ),
              ),
              
              Spacer(),
              
              // Texto del estado de carga (En Oro y Cursivo, elegante)
              Text(
                _estadoCargaText, 
                style: GoogleFonts.greatVibes(color: cB, fontSize: 24, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// PAINTER PERSONALIZADO PARA EL CORAZÓN REALISTA
// =========================================================
class CorazonLlenandosePainter extends CustomPainter {
  final double progreso;
  final Color colorRelleno;
  final Color colorBorde;

  CorazonLlenandosePainter({
    required this.progreso,
    required this.colorRelleno,
    required this.colorBorde,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Definimos el camino (path) del corazón
    Path path = Path();
    double width = size.width;
    double height = size.height;

    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.2 * width, height * 0.1, -0.25 * width, height * 0.6, 0.5 * width, height);
    path.cubicTo(1.25 * width, height * 0.6, 0.8 * width, height * 0.1, 0.5 * width, height * 0.35);
    path.close();

    // 1. Dibujamos el contorno de oro
    Paint paintBorde = Paint()
      ..color = colorBorde
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawPath(path, paintBorde);

    // 2. Creamos la máscara de llenado (líquido) granate
    canvas.save();
    canvas.clipPath(path); // Solo dibujamos DENTRO del corazón

    // Definimos la altura del llenado
    double topLlenado = height * (1.0 - progreso);

    // Dibujamos el rectángulo de relleno (el líquido)
    Paint paintRelleno = Paint()
      ..color = colorRelleno
      ..style = PaintingStyle.fill;
    
    // Pequeño truco para que parezca que el líquido se mueve
    canvas.drawRect(
      Rect.fromLTWH(0, topLlenado, width, height), 
      paintRelleno
    );

    canvas.restore(); // Restauramos el canvas original
  }

  @override
  bool shouldRepaint(covariant CorazonLlenandosePainter oldDelegate) {
    return oldDelegate.progreso != progreso;
  }
}