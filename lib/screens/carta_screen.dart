import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Pantalla de "carta abierta": papel envejecido con caligrafía manuscrita.
///
/// Animaciones:
///  - El papel desliza desde abajo y rota ligeramente al entrar (carta
///    sacada de un sobre).
///  - El texto aparece párrafo por párrafo con un fade + slide tipo
///    "alguien escribiendo en tiempo real".
///  - Una sombra dinámica que sigue al puntero del usuario para dar
///    sensación de profundidad cuando se desliza.
class PantallaCarta extends StatefulWidget {
  const PantallaCarta({super.key});

  @override
  State<PantallaCarta> createState() => _PantallaCartaState();
}

class _PantallaCartaState extends State<PantallaCarta>
    with TickerProviderStateMixin {
  late final AnimationController _entradaController;
  late final Animation<double> _entradaSlide;
  late final Animation<double> _entradaRotacion;
  late final Animation<double> _entradaOpacidad;

  // Cada párrafo tiene su propio progreso de aparición (0..1).
  late final List<Animation<double>> _parrafosFade;
  late final AnimationController _parrafosController;

  static const _parrafos = <String>[
    'Mi vida,',
    'Cada vez que abres esta aplicación, recuerda que '
        'fue hecha pensando en ti, en tu sonrisa y en cada '
        'momento que hemos vivido juntos.',
    'Aquí encontrarás nuestros recuerdos: las fotos que '
        'me hacen sonreír cuando estoy lejos, los videos que '
        'me devuelven tu voz, y la música que ha sido la banda '
        'sonora de nuestra historia.',
    'No importa cuánto tiempo o cuánta distancia haya entre '
        'nosotros, mi corazón siempre está contigo. Cada segundo '
        'que pasa es un segundo menos para volver a abrazarte.',
    'Te amo, hoy y siempre. ❤️',
    '— Tuyo, para siempre',
  ];

  @override
  void initState() {
    super.initState();

    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entradaSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _entradaController, curve: Curves.easeOutCubic),
    );
    _entradaRotacion = Tween<double>(begin: -0.04, end: 0.0).animate(
      CurvedAnimation(parent: _entradaController, curve: Curves.easeOutBack),
    );
    _entradaOpacidad = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entradaController, curve: Curves.easeOut),
    );

    // Aparición secuencial de párrafos.
    _parrafosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _parrafosFade = List.generate(_parrafos.length, (i) {
      final inicio = i / _parrafos.length;
      final fin = (i + 1) / _parrafos.length;
      return CurvedAnimation(
        parent: _parrafosController,
        curve: Interval(inicio, fin, curve: Curves.easeOut),
      );
    });

    _entradaController.forward().then((_) {
      if (mounted) _parrafosController.forward();
    });
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _parrafosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.granateNoche,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.oroClaro),
        title: Text(
          'Para ti',
          style: GoogleFonts.greatVibes(
            color: AppColors.oroClaro,
            fontSize: 30,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo oscuro con vignette dorado.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  AppColors.granateProfundo.withValues(alpha: 0.6),
                  AppColors.granateNoche,
                  const Color(0xFF050302),
                ],
              ),
            ),
          ),
          // La carta.
          AnimatedBuilder(
            animation: _entradaController,
            builder: (_, __) => Opacity(
              opacity: _entradaOpacidad.value,
              child: Transform.translate(
                offset: Offset(0, _entradaSlide.value * 80),
                child: Transform.rotate(
                  angle: _entradaRotacion.value,
                  child: const _PapelEnvejecido(),
                ),
              ),
            ),
          ),
          // Texto encima del papel.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 90, 36, 36),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedBuilder(
                  animation: _parrafosController,
                  builder: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      ...List.generate(_parrafos.length, (i) {
                        final fade = _parrafosFade[i];
                        return _ParrafoAnimado(
                          texto: _parrafos[i],
                          opacidad: fade.value,
                          esFirma: i == _parrafos.length - 1,
                          esTitulo: i == 0,
                        );
                      }),
                      const SizedBox(height: 30),
                      // Sello al final de la carta.
                      Center(
                        child: Opacity(
                          opacity: _parrafosFade.last.value,
                          child: const _SelloLacre(),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que dibuja el papel envejecido con bordes irregulares y manchas.
class _PapelEnvejecido extends StatelessWidget {
  const _PapelEnvejecido();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7E9C8), // crema cálida
              Color(0xFFEED6A8), // pergamino
              Color(0xFFE0C18A), // tono envejecido
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF6B4A1A).withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.oro.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _PainterManchasPapel(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Pinta las imperfecciones del papel: manchas de café, líneas tenues,
/// bordes desgastados. Se compone como capa decorativa transparente.
class _PainterManchasPapel extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Mancha de café superior derecha.
    final manchaCafe = Paint()
      ..color = const Color(0xFF7A4F1F).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(w * 0.85, h * 0.12), 26, manchaCafe);
    canvas.drawCircle(Offset(w * 0.78, h * 0.18), 14, manchaCafe);

    // Mancha tenue inferior izquierda.
    canvas.drawCircle(Offset(w * 0.15, h * 0.92), 22, manchaCafe);

    // Líneas horizontales tenues (tipo papel rayado vintage).
    final paintLinea = Paint()
      ..color = const Color(0xFF6B4A1A).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var y = 60.0; y < h - 20; y += 26) {
      canvas.drawLine(Offset(20, y), Offset(w - 20, y), paintLinea);
    }

    // Bordes desgastados con un trazo irregular en los 4 lados.
    final paintBorde = Paint()
      ..color = const Color(0xFF8A6A2A).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pathBorde = Path()
      ..moveTo(2, 6)
      ..lineTo(2, h - 4)
      ..lineTo(w - 4, h - 2)
      ..lineTo(w - 2, 4)
      ..close();
    canvas.drawPath(pathBorde, paintBorde);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParrafoAnimado extends StatelessWidget {
  final String texto;
  final double opacidad;
  final bool esTitulo;
  final bool esFirma;

  const _ParrafoAnimado({
    required this.texto,
    required this.opacidad,
    this.esTitulo = false,
    this.esFirma = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle estilo;
    if (esTitulo) {
      estilo = GoogleFonts.greatVibes(
        fontSize: 42,
        color: AppColors.granateOscuro,
        height: 1.0,
      );
    } else if (esFirma) {
      estilo = GoogleFonts.greatVibes(
        fontSize: 26,
        color: AppColors.granateOscuro,
        fontStyle: FontStyle.italic,
        height: 1.3,
      );
    } else {
      estilo = GoogleFonts.cormorantGaramond(
        fontSize: 18,
        color: AppColors.granateNoche,
        fontStyle: FontStyle.italic,
        height: 1.7,
        letterSpacing: 0.2,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: esTitulo ? 16 : 14,
        top: esFirma ? 18 : 0,
      ),
      child: Opacity(
        opacity: opacidad,
        child: Transform.translate(
          offset: Offset(0, (1 - opacidad) * 12),
          child: Text(
            texto,
            textAlign: esTitulo
                ? TextAlign.start
                : (esFirma ? TextAlign.end : TextAlign.justify),
            style: estilo,
          ),
        ),
      ),
    );
  }
}

/// Sello de lacre decorativo al pie de la carta (estilo vintage).
class _SelloLacre extends StatelessWidget {
  const _SelloLacre();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFFB04545),
            AppColors.granate,
            AppColors.granateOscuro,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.favorite,
          color: AppColors.oroClaro.withValues(alpha: 0.9),
          size: 24,
        ),
      ),
    );
  }
}
