import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Vista de pantalla completa con tocadiscos animado.
/// Reusa los `ValueNotifier` de la pantalla padre para evitar
/// duplicar el estado de reproducción.
class ReproductorVinilo extends StatefulWidget {
  final ValueNotifier<bool> estaReproduciendoNotifier;
  final ValueNotifier<int> indiceCancionNotifier;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final List<String> miMusica;

  /// Reproductor real para escuchar posición/duración y permitir el seek.
  final AudioPlayer reproductor;

  const ReproductorVinilo({
    super.key,
    required this.estaReproduciendoNotifier,
    required this.indiceCancionNotifier,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.miMusica,
    required this.reproductor,
  });

  @override
  State<ReproductorVinilo> createState() => _ReproductorViniloState();
}

class _ReproductorViniloState extends State<ReproductorVinilo>
    with TickerProviderStateMixin {
  late final AnimationController _viniloController;
  late final AnimationController _brazoController;
  late final AnimationController _visualizerController;
  late final Animation<double> _brazoAnimacion;

  // Notifiers locales para posición y duración. Suscritos a los streams
  // del AudioPlayer; permiten que el slider y los timestamps se actualicen
  // sin reconstruir todo el árbol del reproductor.
  final ValueNotifier<Duration> _posicion = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duracion = ValueNotifier(Duration.zero);
  StreamSubscription<Duration>? _subPosicion;
  StreamSubscription<Duration>? _subDuracion;
  // Mientras el usuario arrastra el slider, ignoramos las actualizaciones
  // automáticas para que el thumb no salte mientras está moviéndolo.
  double? _arrastreSegundos;

  @override
  void initState() {
    super.initState();
    _subPosicion = widget.reproductor.onPositionChanged.listen((p) {
      _posicion.value = p;
    });
    _subDuracion = widget.reproductor.onDurationChanged.listen((d) {
      _duracion.value = d;
    });
    // Tomamos los valores iniciales por si el reproductor ya viene cargado.
    widget.reproductor.getCurrentPosition().then((p) {
      if (mounted && p != null) _posicion.value = p;
    });
    widget.reproductor.getDuration().then((d) {
      if (mounted && d != null) _duracion.value = d;
    });
    // 33⅓ RPM real ≈ 1.8s por vuelta. Sentido horario (turns 0 → 1).
    _viniloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // Brazo: gira ~22° desde su pivote para apoyarse sobre el disco.
    _brazoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Visualizador: ciclo continuo para simular oscilaciones de frecuencia.
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // Brazo:
    //  - REPOSO (begin = -0.06 turns ≈ -22°): el extremo inferior se inclina
    //    a la DERECHA (fuera del disco, sobre el soporte de descanso).
    //  - REPRODUCIENDO (end = +0.05 turns ≈ +18°): el extremo inferior se
    //    inclina a la IZQUIERDA y la aguja queda sobre los surcos del disco.
    //
    // Importante: en Flutter `RotationTransition` con valores positivos rota
    // en sentido HORARIO. Para una columna que parte apuntando hacia abajo,
    // un giro horario mueve la base hacia la izquierda (de 6 → 7 → 8 en la
    // metáfora del reloj). Por eso el reposo es negativo y el playing
    // es positivo.
    _brazoAnimacion = Tween<double>(begin: -0.06, end: 0.05).animate(
      CurvedAnimation(parent: _brazoController, curve: Curves.easeOutCubic),
    );

    if (widget.estaReproduciendoNotifier.value) {
      _viniloController.repeat();
      _brazoController.forward();
    }
    widget.estaReproduciendoNotifier.addListener(_onCambioReproduccion);
  }

  void _onCambioReproduccion() {
    if (!mounted) return;
    if (widget.estaReproduciendoNotifier.value) {
      _viniloController.repeat();
      _brazoController.forward();
    } else {
      _viniloController.stop();
      _brazoController.reverse();
    }
  }

  @override
  void dispose() {
    widget.estaReproduciendoNotifier.removeListener(_onCambioReproduccion);
    _subPosicion?.cancel();
    _subDuracion?.cancel();
    _posicion.dispose();
    _duracion.dispose();
    _viniloController.dispose();
    _brazoController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  String _formatear(Duration d) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(d.inMinutes.remainder(60))}:'
        '${dosDigitos(d.inSeconds.remainder(60))}';
  }

  String _nombreLimpio(String ruta) =>
      ruta.split('/').last.replaceAll('.mp3', '').replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 82% para móvil estrecho, 78% para pantallas más anchas — mantiene la
    // galería visible al fondo sin que el reproductor se sienta apretado.
    final altura = size.width < 480 ? size.height * 0.82 : size.height * 0.78;

    return Container(
      height: altura,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.granateProfundo,
            AppColors.granateNoche,
            Color(0xFF0D0805),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: AppColors.oro.withOpacity(0.4), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: AppColors.oro.withOpacity(0.06),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header con drag-handle, título y botón de cerrar.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Indicador de arrastre centrado.
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.oro.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Botón cerrar a la derecha.
                  Positioned(
                    right: 0,
                    top: -4,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.oro.withOpacity(0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.oroClaro.withOpacity(0.85),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Now Playing',
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: AppColors.oro,
                shadows: [
                  Shadow(
                    color: AppColors.granate.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Nombre de la canción (vista limpia, sin tapar el disco).
            ValueListenableBuilder<int>(
              valueListenable: widget.indiceCancionNotifier,
              builder: (_, indice, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _nombreLimpio(widget.miMusica[indice]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    color: AppColors.oroClaro,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _Tocadiscos(
                indiceCancionNotifier: widget.indiceCancionNotifier,
                estaReproduciendoNotifier: widget.estaReproduciendoNotifier,
                miMusica: widget.miMusica,
                viniloController: _viniloController,
                brazoAnimacion: _brazoAnimacion,
                visualizerController: _visualizerController,
              ),
            ),
            const SizedBox(height: 18),
            // Barra de progreso de la pista con timestamps.
            _BarraProgresoPista(
              posicion: _posicion,
              duracion: _duracion,
              valorArrastre: () => _arrastreSegundos,
              onArrastreInicio: (s) => setState(() => _arrastreSegundos = s),
              onArrastreCambio: (s) => setState(() => _arrastreSegundos = s),
              onArrastreFin: (s) {
                widget.reproductor.seek(Duration(seconds: s.toInt()));
                setState(() => _arrastreSegundos = null);
              },
              formatear: _formatear,
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<bool>(
              valueListenable: widget.estaReproduciendoNotifier,
              builder: (_, reproduciendo, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ViniloControlBtn(
                    icon: Icons.skip_previous_rounded,
                    onTap: widget.onPrevious,
                    size: 52,
                  ),
                  const SizedBox(width: 28),
                  _BotonPlayCentral(
                    reproduciendo: reproduciendo,
                    onPlayPause: widget.onPlayPause,
                  ),
                  const SizedBox(width: 28),
                  _ViniloControlBtn(
                    icon: Icons.skip_next_rounded,
                    onTap: widget.onNext,
                    size: 52,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Tocadiscos extends StatelessWidget {
  final ValueNotifier<int> indiceCancionNotifier;
  final ValueNotifier<bool> estaReproduciendoNotifier;
  final List<String> miMusica;
  final AnimationController viniloController;
  final Animation<double> brazoAnimacion;
  final AnimationController visualizerController;

  const _Tocadiscos({
    required this.indiceCancionNotifier,
    required this.estaReproduciendoNotifier,
    required this.miMusica,
    required this.viniloController,
    required this.brazoAnimacion,
    required this.visualizerController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Base de madera del tocadiscos.
        Container(
          width: 330,
          height: 330,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B6914),
                Color(0xFF6B4E0A),
                Color(0xFF3A2705),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A1A05), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppColors.oro.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(0, -6),
              ),
            ],
          ),
        ),
        // Plato giratorio (parte metálica fija).
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [
                Color(0xFF555555),
                Color(0xFF2A2A2A),
                Color(0xFF0F0F0F),
              ],
              stops: [0.4, 0.85, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // Disco de vinilo girando.
        RepaintBoundary(
          child: RotationTransition(
            turns: viniloController,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF0A0A0A),
                    Color(0xFF000000),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: CustomPaint(
                painter: const _ViniloPainter(),
                child: Center(
                  // Etiqueta central del vinilo (el tradicional papel rojo
                  // con el agujero del eje en el centro).
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFA94545),
                          AppColors.granate,
                          Color(0xFF4A1F1F),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.oro, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.oro.withOpacity(0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF050505),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Brazo del tocadiscos.
        //
        // CLAVE: el pivote (esfera metálica) NO debe rotar — sólo gira el
        // tubo + cabezal alrededor del centro del pivote. Por eso usamos un
        // `Positioned` que contiene un Stack donde:
        //   1. El pivote es un `Container` estático.
        //   2. El brazo (tubo + cabezal + aguja) está dentro de un
        //      `RotationTransition` posicionado debajo del pivote, con
        //      `alignment: Alignment.topCenter` para que rote alrededor de
        //      su extremo superior (que coincide con el pivote).
        //
        // El ángulo va de +0.04 turns (rest, brazo apoyado a la derecha,
        // fuera del disco) a -0.05 turns (playing, inclinado a la izquierda
        // sobre los surcos del disco). Eso da una animación de ~32° similar
        // a un tocadiscos real.
        Positioned(
          right: 30,
          top: 14,
          child: SizedBox(
            width: 30,
            height: 220,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Tubo + cabezal: rotan sobre el pivote.
                Positioned(
                  left: 12, // centra el tubo (6px ancho) bajo el pivote.
                  top: 14,  // arranca justo en el centro del pivote.
                  child: RotationTransition(
                    turns: brazoAnimacion,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tubo del brazo.
                        Container(
                          width: 6,
                          height: 158,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFC8C8C8),
                                Color(0xFF707070),
                                Color(0xFF505050),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 3,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                        // Cartucho (head shell).
                        Container(
                          width: 22,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF606060), Color(0xFF1F1F1F)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFF8A8A8A), width: 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.55),
                                blurRadius: 4,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                        // Aguja: fina línea dorada que toca el surco.
                        Container(
                          width: 1.5,
                          height: 5,
                          color: AppColors.oro,
                        ),
                      ],
                    ),
                  ),
                ),
                // Pivote: ESTÁTICO. Va por encima en el Stack para tapar
                // el extremo superior del tubo y dar la sensación de que el
                // tubo nace desde su interior.
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFE0E0E0),
                          Color(0xFF888888),
                          Color(0xFF333333),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFB0B0B0), width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    // Tornillo central que ancla visualmente el pivote.
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Visualizador de audio: aparece animado solo cuando se reproduce.
        ValueListenableBuilder<bool>(
          valueListenable: estaReproduciendoNotifier,
          builder: (_, reproduciendo, __) => AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: reproduciendo ? -8 : -80,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: reproduciendo ? 1.0 : 0.0,
              child: _AudioVisualizer(controller: visualizerController),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonPlayCentral extends StatelessWidget {
  final bool reproduciendo;
  final VoidCallback onPlayPause;

  const _BotonPlayCentral({
    required this.reproduciendo,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // onPlayPause maneja inteligentemente play/pause/resume.
        onTap: onPlayPause,
        customBorder: const CircleBorder(),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.oro,
                AppColors.oroBrillante,
                AppColors.oro,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4A1F1F), width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.oro.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            reproduciendo ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: const Color(0xFF4A1F1F),
            size: 40,
          ),
        ),
      ),
    );
  }
}

/// Barra de progreso de la pista (slider + timestamps actuales).
///
/// Usa los `ValueNotifier` de posición y duración del padre para que sólo
/// el slider y los timestamps se reconstruyan cada segundo, no toda la
/// pantalla del reproductor.
class _BarraProgresoPista extends StatelessWidget {
  final ValueListenable<Duration> posicion;
  final ValueListenable<Duration> duracion;
  final double? Function() valorArrastre;
  final ValueChanged<double> onArrastreInicio;
  final ValueChanged<double> onArrastreCambio;
  final ValueChanged<double> onArrastreFin;
  final String Function(Duration) formatear;

  const _BarraProgresoPista({
    required this.posicion,
    required this.duracion,
    required this.valorArrastre,
    required this.onArrastreInicio,
    required this.onArrastreCambio,
    required this.onArrastreFin,
    required this.formatear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ValueListenableBuilder<Duration>(
        valueListenable: posicion,
        builder: (_, pos, __) => ValueListenableBuilder<Duration>(
          valueListenable: duracion,
          builder: (_, dur, __) {
            final segTotal = dur.inSeconds.toDouble();
            final segMax = segTotal > 0 ? segTotal : 1.0;
            final segActual =
                (valorArrastre() ?? pos.inSeconds.toDouble()).clamp(0.0, segMax);

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.oro,
                    inactiveTrackColor: AppColors.oro.withOpacity(0.2),
                    thumbColor: AppColors.oroClaro,
                    overlayColor: AppColors.oro.withOpacity(0.18),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    min: 0,
                    max: segMax,
                    value: segActual,
                    onChangeStart: onArrastreInicio,
                    onChanged: onArrastreCambio,
                    onChangeEnd: onArrastreFin,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatear(Duration(seconds: segActual.toInt())),
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.oroClaro.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        formatear(dur),
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.oroClaro.withOpacity(0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pinta los surcos del vinilo + un destello sutil para dar volumen.
class _ViniloPainter extends CustomPainter {
  const _ViniloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Surcos concéntricos con grosor variable.
    final paintSurco = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 28; i++) {
      final radius = 46.0 + (i * 3.2);
      paintSurco
        ..strokeWidth = i.isEven ? 0.6 : 1.0
        ..color = Color.fromRGBO(
          0,
          0,
          0,
          0.55 - (i * 0.012),
        );
      canvas.drawCircle(center, radius, paintSurco);
    }

    // Reflejo radial: sutil banda más clara para dar sensación de vinilo
    // brillante. Se dibuja como un círculo con SweepGradient.
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final reflejo = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.06),
          Colors.transparent,
          Colors.white.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.18, 0.36, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, size.width / 2 - 4, reflejo);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Visualizador de audio dinámico con 24 barras y gradiente vertical.
///
/// Simula la respuesta a frecuencias usando una superposición de senoidales
/// (formas de onda diferentes por banda) para que cada barra se mueva con
/// su propio ritmo, dando la sensación de un ecualizador real.
class _AudioVisualizer extends StatelessWidget {
  final AnimationController controller;

  // Cuántas barras mostramos. Mantén número par para simetría.
  static const int _bandas = 24;

  // "Pesos" pseudo-aleatorios pero estables (no cambian entre frames).
  // Se usa para que cada barra responda con un patrón distinto.
  static final List<double> _frecuenciasPorBanda = List.generate(
    _bandas,
    (i) {
      final centro = (_bandas - 1) / 2;
      final distancia = (i - centro).abs() / centro;
      // Las barras del centro responden más fuerte (como bajos/medios reales).
      return 0.5 + (1 - distancia) * 0.5;
    },
  );

  const _AudioVisualizer({required this.controller});

  double _alturaBarra(int index, double t) {
    // Combinamos tres senoidales con frecuencias diferentes para que
    // cada barra parezca reaccionar a una "frecuencia" distinta.
    final fase = index * 0.45;
    final s1 = math.sin((t * 2 * math.pi) + fase);
    final s2 = math.sin((t * 6 * math.pi) + fase * 1.7);
    final s3 = math.sin((t * 10 * math.pi) + fase * 0.6);
    final mezcla = (s1 * 0.5 + s2 * 0.3 + s3 * 0.2) * 0.5 + 0.5; // 0..1
    return mezcla * _frecuenciasPorBanda[index];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_bandas, (i) {
              final intensidad = _alturaBarra(i, t);
              final h = 6 + intensidad * 50;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 4,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.granate.withOpacity(0.95),
                        AppColors.oro.withOpacity(0.85 + intensidad * 0.15),
                        AppColors.oroClaro.withOpacity(0.6 + intensidad * 0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.oro.withOpacity(intensidad * 0.5),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _ViniloControlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ViniloControlBtn({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  @override
  State<_ViniloControlBtn> createState() => _ViniloControlBtnState();
}

class _ViniloControlBtnState extends State<_ViniloControlBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.identity()..scale(_isPressed ? 0.92 : 1.0),
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFF3A2525)
              : AppColors.granateProfundo,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressed ? AppColors.oro : AppColors.oro.withOpacity(0.5),
            width: _isPressed ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.6 : 0.4),
              blurRadius: _isPressed ? 12 : 8,
              offset: Offset(0, _isPressed ? 6 : 4),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: _isPressed ? AppColors.oroClaro : AppColors.oro,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}
