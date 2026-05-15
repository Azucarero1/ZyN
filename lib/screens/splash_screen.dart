import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/estado_global.dart';
import '../core/estado_jardin.dart';
import '../core/notificaciones.dart';
import '../core/theme.dart';
import 'galeria_screen.dart';

/// Pantalla inicial: muestra un corazón llenándose mientras la app
/// inicializa el estado global, las notificaciones y precarga los assets
/// más pesados (fondo + primeras miniaturas).
class PantallaCargaSplash extends StatefulWidget {
  const PantallaCargaSplash({super.key});

  @override
  State<PantallaCargaSplash> createState() => _PantallaCargaSplashState();
}

class _PantallaCargaSplashState extends State<PantallaCargaSplash>
    with TickerProviderStateMixin {
  static const Duration _duracionAnimacion = Duration(seconds: 4);
  static const int _imagenesAPrecargar = 9;

  late final AnimationController _controller;
  late final AnimationController _pulsoCorazon;
  late final Animation<double> _animation;
  late final Animation<double> _animacionPulso;
  String _estado = 'Iniciando…';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duracionAnimacion);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );

    // Latido cardiaco: dos pulsos rápidos seguidos de una pausa.
    // El TweenSequence emula la curva característica de un latido real.
    _pulsoCorazon = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _animacionPulso = TweenSequence<double>([
      // Primer impulso (sístole).
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.10).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 0.97).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 14,
      ),
      // Segundo impulso (más suave).
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.05).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 14,
      ),
      // Pausa (diástole) — el corazón descansa.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_pulsoCorazon);

    _controller.forward();
    _arrancar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulsoCorazon.dispose();
    super.dispose();
  }

  void _setEstado(String mensaje) {
    if (mounted) setState(() => _estado = mensaje);
  }

  Future<void> _arrancar() async {
    await EstadoGlobal.inicializar();
    // Registra la apertura del jardín (avanza la racha o marchita el jazmín
    // si hace días que no entra).
    await EstadoJardin.registrarApertura();
    _setEstado('Preparando notificaciones…');
    await inicializarNotificaciones();

    if (!mounted) return;
    _setEstado('Preparando texturas…');
    // ignore: use_build_context_synchronously
    await precacheImage(
      const AssetImage('assets/images/MainBackground.jpg'),
      context,
    );

    if (!mounted) return;
    _setEstado('Cargando recuerdos…');
    await _precargarMiniaturas();

    // Saludo solo si la app ya tiene fecha configurada (evita ruido al primer arranque).
    if (EstadoGlobal.fechaReencuentro != null) {
      unawaited(enviarMensajeAleatorio());
    }

    // Si la animación aún no terminó, la aceleramos para no hacer esperar.
    if (_controller.value < 1.0) {
      await _controller.animateTo(1.0,
          duration: const Duration(milliseconds: 400));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (_, __, ___) => const PantallaGaleriaVintage(),
        transitionsBuilder: (_, animacion, __, child) =>
            FadeTransition(opacity: animacion, child: child),
      ),
    );
  }

  Future<void> _precargarMiniaturas() async {
    final recuerdos = EstadoGlobal.recuerdos.value;
    if (recuerdos.isEmpty || !mounted) return;

    final limite =
        recuerdos.length < _imagenesAPrecargar ? recuerdos.length : _imagenesAPrecargar;
    final tareas = <Future<void>>[];
    for (var i = 0; i < limite; i++) {
      final r = recuerdos[i];
      if (r.tipo == TipoMedio.fotoAsset) {
        tareas.add(
          // ignore: use_build_context_synchronously
          precacheImage(ResizeImage(AssetImage(r.archivo), width: 300), context),
        );
      }
    }
    try {
      await Future.wait(tareas, eagerError: false);
    } catch (e) {
      debugPrint('Error precargando miniaturas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de marmol vintage.
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/MainBackground.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Sutil gradiente para mejorar legibilidad sobre el fondo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.18),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'ZyN',
                  style: GoogleFonts.greatVibes(
                    fontSize: 88,
                    fontWeight: FontWeight.bold,
                    color: AppColors.granate,
                    shadows: [
                      Shadow(
                        color: AppColors.oro.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Filete decorativo bajo el logo.
                Container(
                  width: 110,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.oro.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  // El corazón se llena con la animación de carga Y palpita
                  // con su propio ritmo cardíaco (dos pulsos + pausa).
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_animation, _animacionPulso]),
                    builder: (_, __) => Transform.scale(
                      scale: _animacionPulso.value,
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _CorazonLlenandosePainter(
                          progreso: _animation.value,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Estado de carga con transición suave entre mensajes.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _estado,
                    key: ValueKey(_estado),
                    style: GoogleFonts.greatVibes(
                      color: AppColors.oro,
                      fontSize: 26,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinta el corazón con un nivel de "líquido" que sube según [progreso] (0..1).
///
/// Tres capas:
///   1. Sombra suave para dar profundidad.
///   2. Llenado granate con gradiente vertical (más claro arriba).
///   3. Borde oro de doble grosor para el acento vintage.
class _CorazonLlenandosePainter extends CustomPainter {
  final double progreso;

  const _CorazonLlenandosePainter({required this.progreso});

  Path _construirCorazon(double width, double height) {
    return Path()
      ..moveTo(0.5 * width, height * 0.35)
      ..cubicTo(
        0.2 * width, height * 0.1,
        -0.25 * width, height * 0.6,
        0.5 * width, height,
      )
      ..cubicTo(
        1.25 * width, height * 0.6,
        0.8 * width, height * 0.1,
        0.5 * width, height * 0.35,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final path = _construirCorazon(width, height);

    // 1. Sombra: eleva el corazón sobre el fondo de mármol.
    canvas.save();
    canvas.translate(2, 6);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();

    // 2. Llenado: gradiente granate que sube según progreso.
    canvas.save();
    canvas.clipPath(path);
    final topLlenado = height * (1.0 - progreso);
    final rectoLleno = Rect.fromLTWH(0, topLlenado, width, height);
    final paintRelleno = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8E3838),
          AppColors.granate,
          AppColors.granateOscuro,
        ],
      ).createShader(rectoLleno);
    canvas.drawRect(rectoLleno, paintRelleno);
    canvas.restore();

    // 3. Borde dorado con doble trazo para acento vintage.
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.oro.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  @override
  bool shouldRepaint(covariant _CorazonLlenandosePainter old) =>
      old.progreso != progreso;
}

