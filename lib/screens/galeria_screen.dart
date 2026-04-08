import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart' as picker show ImageSource;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math';
import 'dart:io';

import '../core/notificaciones.dart';
import '../core/estado_global.dart';
import '../widgets/widgets_video.dart';
import 'detalle_album_screen.dart';

// Filtro sepia constante para evitar recrearlo en cada build
const matrizSepia = ColorFilter.matrix([
  0.9, 0.1, 0.05, 0, 0,
  0.1, 0.8, 0.05, 0, 0,
  0.1, 0.1, 0.75, 0, 0,
  0,   0,   0,    1, 0,
]);

class PantallaGaleriaVintage extends StatefulWidget {
  const PantallaGaleriaVintage({Key? key}) : super(key: key);
  @override _PantallaGaleriaVintageState createState() => _PantallaGaleriaVintageState();
}
class _PantallaGaleriaVintageState extends State<PantallaGaleriaVintage> {
  // Lista de recuerdos
  List<Map<String, String>> get _misRecuerdos => EstadoGlobal.misRecuerdos;

  // Configuración de música - constantes
  final List<String> _miMusica = const [
    "audio/Anhelo.mp3", "audio/Aventura.mp3", "audio/BabyBeMine.mp3",
    "audio/Inmortal.mp3", "audio/JuanLuisGuerra.mp3", "audio/LlévameContigo.mp3",
    "audio/Loco.mp3", "audio/LokitaPorMí.mp3", "audio/MICORAZONCITO.mp3",
    "audio/QueLocuraEnamorarmeDeTi.mp3"
  ];
  final AudioPlayer _reproductorGlobal = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  // Estado de música con ValueNotifier para optimizar rebuilds
  final ValueNotifier<int> _indiceCancionNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _estaReproduciendoNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _modoAleatorioNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _modoRepetirNotifier = ValueNotifier<bool>(false);
  double _volumenGlobal = 0.8;

  // Getters convenientes
  int get _indiceCancionActual => _indiceCancionNotifier.value;
  bool get _estaReproduciendo => _estaReproduciendoNotifier.value;
  bool get _modoAleatorio => _modoAleatorioNotifier.value;
  bool get _modoRepetir => _modoRepetirNotifier.value;

  DateTime? _fechaReencuentro;
  final ValueNotifier<String> _tiempoRestanteNotifier = ValueNotifier<String>("Configura la fecha ⚙️");
  Timer? _temporizador;

  @override void initState() {
    super.initState();
    _reproductorGlobal.setVolume(_volumenGlobal);
    _reproductorGlobal.onPlayerComplete.listen((event) {
      if (_modoRepetir) {
        _reproducirMusica(_indiceCancionActual);
      } else {
        _siguienteCancion();
      }
    });
    _cargarFechaGuardada();
  }

  @override void dispose() {
    _reproductorGlobal.dispose();
    _temporizador?.cancel();
    _tiempoRestanteNotifier.dispose();
    // Dispose de los nuevos ValueNotifiers
    _indiceCancionNotifier.dispose();
    _estaReproduciendoNotifier.dispose();
    _modoAleatorioNotifier.dispose();
    _modoRepetirNotifier.dispose();
    super.dispose();
  }

  Future<void> _cargarFechaGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getString('fecha_reencuentro');
    if (f != null) { _fechaReencuentro = DateTime.parse(f); _iniciarReloj(); }
  }
  
  void _iniciarReloj() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_fechaReencuentro == null) return;
      final diff = _fechaReencuentro!.difference(DateTime.now());
      if (diff.isNegative) { 
        _tiempoRestanteNotifier.value = "¡Hoy es el gran día! ❤️"; 
        timer.cancel(); 
      } else {
        int d = diff.inDays, h = diff.inHours % 24, m = diff.inMinutes % 60, s = diff.inSeconds % 60;
        if (d == 7 && h == 0 && m == 0 && s == 0) {
          notificacionesPlugin.show(id: 1, title: '¡Falta 1 semana! ⏳', body: 'Ya casi estamos juntos.', payload: detallesNotificacion.toString());
        } else if (d == 1 && h == 0 && m == 0 && s == 0) {
          notificacionesPlugin.show(id: 2, title: '¡Mañana nos vemos! 😍', body: 'Prepara abrazos.', payload: detallesNotificacion.toString());
        }
        _tiempoRestanteNotifier.value = "Faltan $d d, $h h, $m m, $s s";
      }
    });
  }

  Future<void> _anadirRecuerdo() async {
    try {
      // Multi-selección de fotos y videos
      final List<XFile> archivos = await _picker.pickMultiImage(imageQuality: 50);

      // También permitir seleccionar videos
      final XFile? video = await _picker.pickVideo(source: picker.ImageSource.gallery);

      int agregados = 0;

      // Procesar imágenes seleccionadas
      for (final arch in archivos) {
        bool esVid = arch.path.toLowerCase().endsWith('.mp4') ||
                     arch.path.toLowerCase().endsWith('.mov') ||
                     arch.path.toLowerCase().endsWith('.avi');
        setState(() => EstadoGlobal.misRecuerdos.insert(0, {
          "tipo": esVid ? "video_local" : "foto_local",
          "archivo": arch.path
        }));
        agregados++;
      }

      // Procesar video individual si se seleccionó
      if (video != null) {
        setState(() => EstadoGlobal.misRecuerdos.insert(0, {
          "tipo": "video_local",
          "archivo": video.path
        }));
        agregados++;
      }

      if (agregados > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("¡$agregados recuerdos añadidos!"),
          backgroundColor: const Color(0xFF6B2A2A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      print("Error al elegir archivos: $e");
    }
  }
  
  void _mostrarConfiguracion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConfiguracionSheet(
        fechaReencuentro: _fechaReencuentro,
        volumenGlobal: _volumenGlobal,
        reproductor: _reproductorGlobal,
        onFechaChanged: (fecha) {
          setState(() {
            _fechaReencuentro = fecha;
            _iniciarReloj();
          });
        },
        onVolumenChanged: (volumen) {
          setState(() => _volumenGlobal = volumen);
        },
      ),
    );
  }
  
  void _reproducirMusica(int i) async {
    await _reproductorGlobal.stop();
    await _reproductorGlobal.play(AssetSource(_miMusica[i]));
    _indiceCancionNotifier.value = i;
    _estaReproduciendoNotifier.value = true;
  }

  void _pausarOPlay() async {
    if (_estaReproduciendo) {
      await _reproductorGlobal.pause();
      _estaReproduciendoNotifier.value = false;
    } else {
      await _reproductorGlobal.resume();
      _estaReproduciendoNotifier.value = true;
    }
  }

  void _siguienteCancion() {
    final nuevoIndice = _modoAleatorio
        ? Random().nextInt(_miMusica.length)
        : (_indiceCancionActual + 1) % _miMusica.length;
    _reproducirMusica(nuevoIndice);
  }

  void _cancionAnterior() {
    final nuevoIndice = (_indiceCancionActual - 1 + _miMusica.length) % _miMusica.length;
    _reproducirMusica(nuevoIndice);
  }

  void _toggleAleatorio() {
    _modoAleatorioNotifier.value = !_modoAleatorio;
  }

  void _toggleRepetir() {
    _modoRepetirNotifier.value = !_modoRepetir;
  }

  @override Widget build(BuildContext context) {
    final cT = Color(0xFF6B2A2A);
    double factorEscala = EstadoGlobal.escalaApp.value;
    int columnasCalculadas = (3 / factorEscala).round().clamp(1, 6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/MainBackground.jpg'), fit: BoxFit.cover)),
        child: SafeArea(child: Column(children: [
          // HEADER REDISEÑADO con gradiente y sombras elegantes
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B2A2A).withOpacity(0.95),
                  const Color(0xFF4A1A1A).withOpacity(0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFB89A6A).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B2A2A).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFB89A6A).withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo ZyN con efecto de brillo
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFFB89A6A),
                      const Color(0xFFE8D4A8),
                      const Color(0xFFB89A6A),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    'ZyN',
                    style: GoogleFonts.greatVibes(
                      fontSize: 42 * factorEscala,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                // Cuenta regresiva con fondo sutil
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB89A6A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFB89A6A).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ValueListenableBuilder<String>(
                      valueListenable: _tiempoRestanteNotifier,
                      builder: (context, valorTiempo, child) {
                        return Text(
                          valorTiempo,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            color: const Color(0xFFE8D4A8),
                            fontSize: 15 * factorEscala,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        );
                      }
                    ),
                  )
                ),
                // Botones con estilo consistente
                Row(
                  children: [
                    _buildHeaderButton(
                      Icons.add_a_photo_outlined,
                      cT,
                      26 * factorEscala,
                      _anadirRecuerdo,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderButton(
                      Icons.settings_outlined,
                      cT,
                      26 * factorEscala,
                      _mostrarConfiguracion,
                    ),
                  ]
                )
              ]
            )
          ),
          
          // CONTENIDO PRINCIPAL: GridView o Estado Vacío
          Expanded(
            child: _misRecuerdos.isEmpty
                ? _EstadoVacioVintage(factorEscala: factorEscala)
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    cacheExtent: 200.0,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnasCalculadas,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.85
                    ),
                    itemCount: _misRecuerdos.length,
                    itemBuilder: (context, index) {
                      final rec = _misRecuerdos[index];
                      final tag = '${rec["archivo"]}-$index';

                      return _AnimatedMemoryCard(
                        rec: rec,
                        tag: tag,
                        factorEscala: factorEscala,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PantallaDetalleAlbum(
                            recuerdos: _misRecuerdos,
                            indiceInicial: index
                          )
                        )),
                        child: _crearMiniatura(rec),
                      );
                    }
                  ),
          ),
          
          // REPRODUCTOR VINTAGE REDISEÑADO
          _VintageRadioPlayer(
            factorEscala: factorEscala,
            indiceCancionNotifier: _indiceCancionNotifier,
            estaReproduciendoNotifier: _estaReproduciendoNotifier,
            modoAleatorioNotifier: _modoAleatorioNotifier,
            modoRepetirNotifier: _modoRepetirNotifier,
            miMusica: _miMusica,
            onPlayPause: _pausarOPlay,
            onNext: _siguienteCancion,
            onPrevious: _cancionAnterior,
            onToggleAleatorio: _toggleAleatorio,
            onToggleRepetir: _toggleRepetir,
            onReproducir: _reproducirMusica,
            reproductor: _reproductorGlobal,
          )
        ])),
      ),
    );
  }
  
  Widget _crearMiniatura(Map<String, String> rec) {
    final tipo = rec["tipo"];
    final archivo = rec["archivo"];

    if (archivo == null) return const SizedBox.shrink();

    // Fotos de assets - con resize para memoria eficiente
    if (tipo == "foto") {
      return Image(
        image: ResizeImage(AssetImage(archivo), width: 300),
        fit: BoxFit.cover,
        gaplessPlayback: true, // Evitar flash blanco al reciclar
      );
    }

    // Fotos locales del usuario - resize agresivo para no llenar RAM
    if (tipo == "foto_local") {
      if (kIsWeb) {
        return Image.network(
          archivo,
          fit: BoxFit.cover,
          width: 300,
          cacheWidth: 300,
        );
      }
      return Image(
        image: ResizeImage(FileImage(File(archivo)), width: 300),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    // Videos - usar thumbnail optimizado
    final esLocal = tipo == "video_local";
    return IgnorePointer(
      child: MiniaturaVideoAutomatica(
        key: ValueKey(archivo),
        rutaVideo: archivo,
        esLocal: esLocal,
      ),
    );
  }

  // Widget helper para botones del header con efectos premium
  Widget _buildHeaderButton(IconData icon, Color color, double size, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFB89A6A).withOpacity(0.2), const Color(0xFFB89A6A).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB89A6A).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Icon(icon, color: const Color(0xFFE8D4A8), size: size),
      ),
    );
  }
}

/// Card animada para recuerdos con efecto de escala al presionar
class _AnimatedMemoryCard extends StatefulWidget {
  final Map<String, String> rec;
  final String tag;
  final double factorEscala;
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedMemoryCard({
    Key? key,
    required this.rec,
    required this.tag,
    required this.factorEscala,
    required this.onTap,
    required this.child,
  }) : super(key: key);

  @override
  State<_AnimatedMemoryCard> createState() => _AnimatedMemoryCardState();
}

class _AnimatedMemoryCardState extends State<_AnimatedMemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final cB = const Color(0xFFB89A6A);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.75),
                    Colors.white.withOpacity(0.55),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10)
                ),
                border: Border.all(
                  color: cB.withOpacity(0.8),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B2A2A).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(4, 6),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 8,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(5),
              child: Hero(
                tag: widget.tag,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(6)
                  ),
                  child: ColorFiltered(
                    colorFilter: matrizSepia,
                    child: widget.child
                  )
                )
              )
            ),
          ),
        ),
      ),
    );
  }
}

// ============= WIDGETS DEL REPRODUCTOR VINTAGE =============

class _VintageRadioPlayer extends StatelessWidget {
  final double factorEscala;
  final ValueNotifier<int> indiceCancionNotifier;
  final ValueNotifier<bool> estaReproduciendoNotifier;
  final ValueNotifier<bool> modoAleatorioNotifier;
  final ValueNotifier<bool> modoRepetirNotifier;
  final List<String> miMusica;
  final VoidCallback onPlayPause, onNext, onPrevious, onToggleAleatorio, onToggleRepetir;
  final Function(int) onReproducir;
  final AudioPlayer reproductor;

  const _VintageRadioPlayer({
    Key? key,
    required this.factorEscala,
    required this.indiceCancionNotifier,
    required this.estaReproduciendoNotifier,
    required this.modoAleatorioNotifier,
    required this.modoRepetirNotifier,
    required this.miMusica,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleAleatorio,
    required this.onToggleRepetir,
    required this.onReproducir,
    required this.reproductor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cT = const Color(0xFF6B2A2A);
    final cB = const Color(0xFFB89A6A);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * factorEscala, vertical: 12),
      padding: EdgeInsets.all(16 * factorEscala),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A2525), Color(0xFF6B2A2A), Color(0xFF4A1F1F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cB.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display - Tocable para abrir vinilo
          GestureDetector(
            onTap: () {
              final indice = indiceCancionNotifier.value;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                enableDrag: true,
                builder: (context) => _ReproductorVinilo(
                  cancionNombre: miMusica[indice].split('/').last.replaceAll('.mp3', ''),
                  estaReproduciendoNotifier: estaReproduciendoNotifier,
                  indiceCancionNotifier: indiceCancionNotifier,
                  onPlayPause: onPlayPause,
                  onNext: onNext,
                  onPrevious: onPrevious,
                  onReproducir: () => onReproducir(indice),
                  miMusica: miMusica,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * factorEscala, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1515),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cB.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note_outlined, color: cB, size: 18 * factorEscala),
                  SizedBox(width: 12 * factorEscala),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: indiceCancionNotifier,
                      builder: (context, indice, _) => ValueListenableBuilder<bool>(
                        valueListenable: estaReproduciendoNotifier,
                        builder: (context, reproduciendo, _) => Text(
                          reproduciendo
                            ? miMusica[indice].split('/').last.replaceAll('.mp3', '').replaceAll('_', ' ')
                            : "Presiona Play",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            color: const Color(0xFFE8D4A8),
                            fontSize: 16 * factorEscala,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * factorEscala),
                  Icon(Icons.music_note_outlined, color: cB, size: 18 * factorEscala),
                ],
              ),
            ),
          ),
          SizedBox(height: 16 * factorEscala),
          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Knob(icon: Icons.shuffle_rounded, notifier: modoAleatorioNotifier, onTap: onToggleAleatorio, size: 36 * factorEscala),
              SizedBox(width: 20 * factorEscala),
              _RoundBtn(icon: Icons.skip_previous_rounded, onTap: onPrevious, size: 48 * factorEscala, cB: cB, cT: cT),
              SizedBox(width: 16 * factorEscala),
              // Play/Pause
              ValueListenableBuilder<int>(
                valueListenable: indiceCancionNotifier,
                builder: (context, indice, _) => ValueListenableBuilder<bool>(
                  valueListenable: estaReproduciendoNotifier,
                  builder: (context, reproduciendo, _) => GestureDetector(
                    onTap: reproduciendo ? onPlayPause : () => onReproducir(indice),
                    child: Container(
                      width: 64 * factorEscala,
                      height: 64 * factorEscala,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [cB, const Color(0xFFD4B896), cB]),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4A1F1F), width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Icon(
                        reproduciendo ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF4A1F1F),
                        size: 36 * factorEscala,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16 * factorEscala),
              _RoundBtn(icon: Icons.skip_next_rounded, onTap: onNext, size: 48 * factorEscala, cB: cB, cT: cT),
              SizedBox(width: 20 * factorEscala),
              _Knob(icon: Icons.repeat_rounded, notifier: modoRepetirNotifier, onTap: onToggleRepetir, size: 36 * factorEscala),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color cB, cT;

  const _RoundBtn({Key? key, required this.icon, required this.onTap, required this.size, required this.cB, required this.cT}) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cT.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: cB.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: cB, size: size * 0.5),
    ),
  );
}

class _Knob extends StatelessWidget {
  final IconData icon;
  final ValueNotifier<bool> notifier;
  final VoidCallback onTap;
  final double size;

  const _Knob({Key? key, required this.icon, required this.notifier, required this.onTap, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: notifier,
    builder: (context, activo, _) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: activo ? [const Color(0xFFB89A6A), const Color(0xFFE8D4A8)] : [const Color(0xFF6B2A2A), const Color(0xFF4A1F1F)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB89A6A).withOpacity(activo ? 1 : 0.3), width: 2),
          boxShadow: activo ? [BoxShadow(color: const Color(0xFFB89A6A).withOpacity(0.5), blurRadius: 12)] : null,
        ),
        child: Icon(icon, color: activo ? const Color(0xFF4A1F1F) : const Color(0xFFB89A6A).withOpacity(0.6), size: size * 0.4),
      ),
    ),
  );
}

// ============= SHEET DE CONFIGURACIÓN MEJORADO =============

class _ConfiguracionSheet extends StatefulWidget {
  final DateTime? fechaReencuentro;
  final double volumenGlobal;
  final AudioPlayer reproductor;
  final Function(DateTime) onFechaChanged;
  final Function(double) onVolumenChanged;

  const _ConfiguracionSheet({
    Key? key,
    required this.fechaReencuentro,
    required this.volumenGlobal,
    required this.reproductor,
    required this.onFechaChanged,
    required this.onVolumenChanged,
  }) : super(key: key);

  @override
  State<_ConfiguracionSheet> createState() => _ConfiguracionSheetState();
}

class _ConfiguracionSheetState extends State<_ConfiguracionSheet> {
  late double _volumen;

  @override
  void initState() {
    super.initState();
    _volumen = widget.volumenGlobal;
  }

  @override
  Widget build(BuildContext context) {
    final cT = const Color(0xFF6B2A2A);
    final cB = const Color(0xFFB89A6A);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4EFEA), Color(0xFFE8E0D5)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: cB, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 4, decoration: BoxDecoration(color: cB.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Configuración', style: GoogleFonts.greatVibes(fontSize: 42, color: cT)),
            const SizedBox(height: 24),
            _buildOption(
              icon: Icons.hourglass_bottom_rounded,
              title: 'Día de nuestro encuentro',
              subtitle: widget.fechaReencuentro != null
                  ? '${widget.fechaReencuentro!.day}/${widget.fechaReencuentro!.month}/${widget.fechaReencuentro!.year}'
                  : 'Toca para elegir la fecha',
              cT: cT, cB: cB,
              onTap: () async {
                final sel = await showDatePicker(
                  context: context,
                  initialDate: widget.fechaReencuentro ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: cT, onPrimary: Colors.white, onSurface: cT)),
                    child: child!,
                  ),
                );
                if (sel != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('fecha_reencuentro', sel.toIso8601String());
                  widget.onFechaChanged(sel);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.volume_up_rounded,
              title: 'Volumen de Música',
              subtitle: '${(_volumen * 100).round()}%',
              cT: cT, cB: cB,
              trailing: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: cB,
                  inactiveTrackColor: cB.withOpacity(0.3),
                  thumbColor: cB,
                  overlayColor: cB.withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _volumen,
                  onChanged: (v) {
                    setState(() => _volumen = v);
                    widget.onVolumenChanged(v);
                    widget.reproductor.setVolume(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.zoom_out_map_rounded,
              title: 'Tamaño de la Galería',
              subtitle: '${(EstadoGlobal.escalaApp.value * 100).round()}%',
              cT: cT, cB: cB,
              trailing: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: cB,
                  inactiveTrackColor: cB.withOpacity(0.3),
                  thumbColor: cB,
                  overlayColor: cB.withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: EstadoGlobal.escalaApp.value,
                  min: 0.5,
                  max: 1.5,
                  onChanged: (v) {
                    setState(() {});
                    EstadoGlobal.cambiarEscala(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cT,
    required Color cB,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cB.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: cT, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: cB, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.cormorantGaramond(color: cT, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: TextStyle(color: cB.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              ),
              if (trailing != null) SizedBox(width: 100, child: trailing),
              if (trailing == null && onTap != null) Icon(Icons.chevron_right_rounded, color: cB),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= ESTADO VACÍO VINTAGE =============

class _EstadoVacioVintage extends StatelessWidget {
  final double factorEscala;

  const _EstadoVacioVintage({Key? key, required this.factorEscala}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cT = const Color(0xFF6B2A2A);
    final cB = const Color(0xFFB89A6A);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Marco vintage decorativo superior
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, cB.withOpacity(0.5), Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Icono de cámara vintage con animación sutil
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 30),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cT.withOpacity(0.8),
                              cT,
                              cT.withOpacity(0.9),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: cB, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: cB.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 55,
                          color: cB,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Título vintage
              Text(
                'Álbum de Recuerdos',
                textAlign: TextAlign.center,
                style: GoogleFonts.greatVibes(
                  fontSize: 36 * factorEscala,
                  color: cT,
                  shadows: [
                    Shadow(
                      color: cB.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Línea decorativa
              Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cB.withOpacity(0.3), cB, cB.withOpacity(0.3)],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Texto descriptivo
              Text(
                'Tu colección está esperando ser llenada con momentos especiales',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18 * factorEscala,
                  color: cT.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 35),

              // Instrucción con icono
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border.all(color: cB.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_outlined, color: cB, size: 24 * factorEscala),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Toca el botón de cámara para añadir tus fotos y videos',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 15 * factorEscala,
                          color: cT,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Marco vintage decorativo inferior
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, cB.withOpacity(0.5), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= REPRODUCTOR DE VINILO PREMIUM =============

class _ReproductorVinilo extends StatefulWidget {
  final String cancionNombre;
  final ValueNotifier<bool> estaReproduciendoNotifier;
  final ValueNotifier<int> indiceCancionNotifier;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onReproducir;
  final List<String> miMusica;

  const _ReproductorVinilo({
    Key? key,
    required this.cancionNombre,
    required this.estaReproduciendoNotifier,
    required this.indiceCancionNotifier,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onReproducir,
    required this.miMusica,
  }) : super(key: key);

  @override
  State<_ReproductorVinilo> createState() => _ReproductorViniloState();
}

class _ReproductorViniloState extends State<_ReproductorVinilo>
    with TickerProviderStateMixin {
  late AnimationController _viniloController;
  late AnimationController _brazoController;
  late AnimationController _visualizerController;
  late Animation<double> _brazoAnimacion;

  @override
  void initState() {
    super.initState();
    _viniloController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _brazoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _brazoAnimacion = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _brazoController, curve: Curves.easeInOutQuad),
    );

    // Iniciar si está reproduciendo
    if (widget.estaReproduciendoNotifier.value) {
      _viniloController.repeat();
      _brazoController.forward();
    }

    // Escuchar cambios del estado de reproducción
    widget.estaReproduciendoNotifier.addListener(_onEstadoReproduccionCambio);
  }

  void _onEstadoReproduccionCambio() {
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
    widget.estaReproduciendoNotifier.removeListener(_onEstadoReproduccionCambio);
    _viniloController.dispose();
    _brazoController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cT = const Color(0xFF6B2A2A);
    final cB = const Color(0xFFB89A6A);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A1515),
            Color(0xFF1A0F0A),
            Color(0xFF0D0805),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle de arrastre
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: cB.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Título
            Text(
              'Now Playing',
              style: GoogleFonts.greatVibes(
                fontSize: 32,
                color: cB,
                shadows: [
                  Shadow(color: cT.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Área del tocadiscos
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base de madera
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B6914),
                          Color(0xFF6B4E0A),
                          Color(0xFF4A3505),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                  ),

                  // Plato metálico
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF444444),
                          Color(0xFF222222),
                          Color(0xFF111111),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF666666), width: 2),
                    ),
                  ),

                  // Vinilo giratorio
                  RotationTransition(
                    turns: _viniloController,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFF111111),
                            Color(0xFF0A0A0A),
                            Color(0xFF050505),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF333333), width: 1),
                      ),
                      child: CustomPaint(
                        painter: _ViniloPainter(),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cT.withOpacity(0.8), cT],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: cB, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: cB.withOpacity(0.3),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(Icons.music_note_outlined, color: cB, size: 30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Etiqueta con nombre de canción
                  Positioned(
                    top: 60,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.indiceCancionNotifier,
                      builder: (context, indice, _) {
                        return Container(
                          width: 180,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cB.withOpacity(0.3)),
                          ),
                          child: Text(
                            widget.miMusica[indice].split('/').last.replaceAll('.mp3', '').replaceAll('_', ' '),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: const Color(0xFFE8D4A8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),

                  // Brazo del tocadiscos
                  Positioned(
                    right: 40,
                    top: 20,
                    child: RotationTransition(
                      turns: _brazoAnimacion,
                      alignment: Alignment.topRight,
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF888888), Color(0xFF444444)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFAAAAAA)),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF999999), Color(0xFF666666)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF666666)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Visualizador de audio
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.estaReproduciendoNotifier,
                    builder: (context, reproduciendo, _) {
                      return reproduciendo
                          ? Positioned(
                              bottom: 20,
                              child: _AudioVisualizer(
                                color: cB,
                                controller: _visualizerController,
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Controles - AHORA FUNCIONAN CORRECTAMENTE
            ValueListenableBuilder<bool>(
              valueListenable: widget.estaReproduciendoNotifier,
              builder: (context, reproduciendo, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: widget.indiceCancionNotifier,
                  builder: (context, indice, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Previous
                        _ViniloControlBtn(
                          icon: Icons.skip_previous_rounded,
                          onTap: () {
                            widget.onPrevious();
                          },
                          size: 50,
                          cB: cB,
                        ),
                        const SizedBox(width: 30),
                        // Play/Pause principal
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (reproduciendo) {
                                widget.onPlayPause();
                              } else {
                                widget.onReproducir();
                              }
                            },
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cB, const Color(0xFFD4B896), cB],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF4A1F1F), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: cB.withOpacity(0.4),
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
                        ),
                        const SizedBox(width: 30),
                        // Next
                        _ViniloControlBtn(
                          icon: Icons.skip_next_rounded,
                          onTap: () {
                            widget.onNext();
                          },
                          size: 50,
                          cB: cB,
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Pintor personalizado para el vinilo (surcos)
class _ViniloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dibujar surcos del vinilo
    for (int i = 0; i < 15; i++) {
      final radius = 50.0 + (i * 6);
      paint.color = const Color(0xFF333333).withOpacity(0.3 + (i * 0.02));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Visualizador de audio animado
class _AudioVisualizer extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _AudioVisualizer({Key? key, required this.color, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (controller.value + delay) % 1.0;
            final height = 10 + (value * 25);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6 + (value * 0.4)),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        );
      }),
    );
  }
}

// Botón de control del vinilo - AHORA FUNCIONA
class _ViniloControlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color cB;

  const _ViniloControlBtn({
    Key? key,
    required this.icon,
    required this.onTap,
    required this.size,
    required this.cB,
  }) : super(key: key);

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
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFF3A2525) : const Color(0xFF2A1515),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressed ? widget.cB : widget.cB.withOpacity(0.5),
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
        transform: Matrix4.identity()..scale(_isPressed ? 0.92 : 1.0),
        child: Icon(
          widget.icon,
          color: _isPressed ? const Color(0xFFE8D4A8) : widget.cB,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}