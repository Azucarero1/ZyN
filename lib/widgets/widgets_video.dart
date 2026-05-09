import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../core/theme.dart';

// Re-exportamos `matrizSepia` para que los archivos antiguos que importan
// `widgets_video.dart` lo encuentren sin cambios.
export '../core/theme.dart' show matrizSepia, AppColors;

/// Miniatura ligera para videos: usa un thumbnail JPEG en lugar de
/// inicializar un `VideoPlayerController` completo (mucho más rápido y
/// con un consumo de memoria mínimo en grids grandes).
class MiniaturaVideoAutomatica extends StatefulWidget {
  final String rutaVideo;
  final bool esLocal;

  const MiniaturaVideoAutomatica({
    super.key,
    required this.rutaVideo,
    this.esLocal = false,
  });

  @override
  State<MiniaturaVideoAutomatica> createState() =>
      _MiniaturaVideoAutomaticaState();
}

class _MiniaturaVideoAutomaticaState extends State<MiniaturaVideoAutomatica> {
  Uint8List? _thumbnailData;
  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _generarThumbnail();
  }

  Future<void> _generarThumbnail() async {
    try {
      final ruta = widget.esLocal
          ? widget.rutaVideo
          : await _copiarAssetATemp(widget.rutaVideo);

      final thumbnail = await VideoThumbnail.thumbnailData(
        video: ruta,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );

      if (!mounted) return;
      setState(() {
        _thumbnailData = thumbnail;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('No pude generar el thumbnail de ${widget.rutaVideo}: $e');
      if (!mounted) return;
      setState(() {
        _error = true;
        _cargando = false;
      });
    }
  }

  /// Copia un asset al directorio temporal para que `VideoThumbnail`
  /// pueda leerlo. Reusa el archivo si ya existe.
  Future<String> _copiarAssetATemp(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${assetPath.hashCode}.mp4');

    if (await tempFile.exists()) return tempFile.path;

    final byteData = await rootBundle.load(assetPath);
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());
    return tempFile.path;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.oro),
        ),
      );
    }

    if (_error || _thumbnailData == null) {
      return const _Fallback();
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_thumbnailData!, fit: BoxFit.cover, cacheWidth: 300),
          ColoredBox(color: AppColors.granate.withOpacity(0.1)),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.oro.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.granate,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black12,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.granate.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.videocam_rounded,
            color: AppColors.oro,
            size: 30,
          ),
        ),
      ),
    );
  }
}

/// Reproductor de video con marco vintage y controles personalizados.
/// Usa un `ValueListenable` interno (`VideoPlayerController` ya lo expone)
/// para evitar `setState` en cada frame del progreso.
class ReproductorVideoControlesVintage extends StatefulWidget {
  final String rutaVideo;
  final bool esLocal;

  const ReproductorVideoControlesVintage({
    super.key,
    required this.rutaVideo,
    this.esLocal = false,
  });

  @override
  State<ReproductorVideoControlesVintage> createState() =>
      _ReproductorVideoControlesVintageState();
}

class _ReproductorVideoControlesVintageState
    extends State<ReproductorVideoControlesVintage> {
  VideoPlayerController? _controlador;
  bool _tieneError = false;
  bool _silenciado = false;
  double? _valorArrastre;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final controlador = widget.esLocal
          ? (kIsWeb
              ? VideoPlayerController.networkUrl(Uri.parse(widget.rutaVideo))
              : VideoPlayerController.file(File(widget.rutaVideo)))
          : VideoPlayerController.asset(widget.rutaVideo);
      _controlador = controlador;

      await controlador.initialize();
      if (!mounted) {
        await controlador.dispose();
        return;
      }
      await controlador.setLooping(true);
      await controlador.play();
      setState(() {});
    } catch (e) {
      debugPrint('Error inicializando video ${widget.rutaVideo}: $e');
      if (mounted) setState(() => _tieneError = true);
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  String _formatear(Duration d) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(d.inMinutes.remainder(60))}:${dosDigitos(d.inSeconds.remainder(60))}';
  }

  void _retroceder() {
    final c = _controlador;
    if (c == null) return;
    final nueva = c.value.position - const Duration(seconds: 10);
    c.seekTo(nueva < Duration.zero ? Duration.zero : nueva);
  }

  void _adelantar() {
    final c = _controlador;
    if (c == null) return;
    final nueva = c.value.position + const Duration(seconds: 10);
    c.seekTo(nueva > c.value.duration ? c.value.duration : nueva);
  }

  void _reiniciar() {
    final c = _controlador;
    if (c == null) return;
    c.seekTo(Duration.zero);
    c.play();
  }

  void _alternarSilencio() {
    final c = _controlador;
    if (c == null) return;
    setState(() {
      _silenciado = !_silenciado;
      c.setVolume(_silenciado ? 0.0 : 1.0);
    });
  }

  void _alternarPlayPause() {
    final c = _controlador;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tieneError) {
      return const Center(
        child: Icon(Icons.broken_image_rounded,
            color: Colors.white54, size: 60),
      );
    }
    final c = _controlador;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.oro),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C241B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.oro, width: 2),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Center(
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: 0.99,
                      child: ColorFiltered(
                        colorFilter: matrizSepia,
                        child: VideoPlayer(c),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _PanelControles(
            controlador: c,
            silenciado: _silenciado,
            valorArrastre: _valorArrastre,
            formatear: _formatear,
            onSliderStart: (v) => setState(() => _valorArrastre = v),
            onSliderChange: (v) => setState(() => _valorArrastre = v),
            onSliderEnd: (v) {
              c.seekTo(Duration(seconds: v.toInt()));
              setState(() => _valorArrastre = null);
            },
            onPlayPause: _alternarPlayPause,
            onRetroceder: _retroceder,
            onAdelantar: _adelantar,
            onReiniciar: _reiniciar,
            onAlternarSilencio: _alternarSilencio,
          ),
        ],
      ),
    );
  }
}

class _PanelControles extends StatelessWidget {
  final VideoPlayerController controlador;
  final bool silenciado;
  final double? valorArrastre;
  final String Function(Duration) formatear;
  final ValueChanged<double> onSliderStart;
  final ValueChanged<double> onSliderChange;
  final ValueChanged<double> onSliderEnd;
  final VoidCallback onPlayPause;
  final VoidCallback onRetroceder;
  final VoidCallback onAdelantar;
  final VoidCallback onReiniciar;
  final VoidCallback onAlternarSilencio;

  const _PanelControles({
    required this.controlador,
    required this.silenciado,
    required this.valorArrastre,
    required this.formatear,
    required this.onSliderStart,
    required this.onSliderChange,
    required this.onSliderEnd,
    required this.onPlayPause,
    required this.onRetroceder,
    required this.onAdelantar,
    required this.onReiniciar,
    required this.onAlternarSilencio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.granate,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(top: BorderSide(color: AppColors.oro, width: 2)),
      ),
      child: Stack(
        children: [
          const Positioned(top: 6, left: 6, child: _Tornillo()),
          const Positioned(top: 6, right: 6, child: _Tornillo()),
          const Positioned(bottom: 6, left: 6, child: _Tornillo()),
          const Positioned(bottom: 6, right: 6, child: _Tornillo()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controlador,
                builder: (_, valor, __) => Row(
                  children: [
                    Text(
                      formatear(valor.position),
                      style: GoogleFonts.greatVibes(
                        fontSize: 22,
                        color: AppColors.oro,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.oro,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: AppColors.oro,
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.0),
                        ),
                        child: Slider(
                          value: (valorArrastre ??
                                  valor.position.inSeconds.toDouble())
                              .clamp(0.0, valor.duration.inSeconds.toDouble()),
                          min: 0.0,
                          max: valor.duration.inSeconds > 0
                              ? valor.duration.inSeconds.toDouble()
                              : 1.0,
                          onChangeStart: onSliderStart,
                          onChanged: onSliderChange,
                          onChangeEnd: onSliderEnd,
                        ),
                      ),
                    ),
                    Text(
                      formatear(valor.duration),
                      style: GoogleFonts.greatVibes(
                        fontSize: 22,
                        color: AppColors.oro,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      silenciado
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: AppColors.oro,
                      size: 28,
                    ),
                    onPressed: onAlternarSilencio,
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded,
                        color: AppColors.oro, size: 32),
                    onPressed: onRetroceder,
                  ),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controlador,
                    builder: (_, valor, __) => GestureDetector(
                      onTap: onPlayPause,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.oro,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              offset: Offset(2, 3),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.white30,
                              offset: Offset(-1, -1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          valor.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.granate,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded,
                        color: AppColors.oro, size: 32),
                    onPressed: onAdelantar,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.oro, size: 28),
                    onPressed: onReiniciar,
                  ),
                ],
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tornillo extends StatelessWidget {
  const _Tornillo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF8B6C42), Color(0xFF4A3515)],
        ),
        border: Border.all(color: Colors.black38),
        boxShadow: const [
          BoxShadow(
            color: Colors.white24,
            offset: Offset(0.5, 0.5),
            blurRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(width: 6, height: 1, color: Colors.black45),
      ),
    );
  }
}
