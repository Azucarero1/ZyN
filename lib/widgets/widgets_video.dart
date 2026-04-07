import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart'; 
import 'dart:io';

const ColorFilter matrizSepia = ColorFilter.matrix([
  0.9, 0.1, 0.05, 0, 0,
  0.1, 0.8, 0.05, 0, 0,
  0.1, 0.1, 0.75, 0, 0,
  0,   0,   0,    1, 0,
]);

class MiniaturaVideoAutomatica extends StatefulWidget {
  final String rutaVideo;
  final bool esLocal;
  MiniaturaVideoAutomatica({Key? key, required this.rutaVideo, this.esLocal = false}) : super(key: key);
  @override _MiniaturaVideoAutomaticaState createState() => _MiniaturaVideoAutomaticaState();
}
class _MiniaturaVideoAutomaticaState extends State<MiniaturaVideoAutomatica> {
  late VideoPlayerController _controladorMiniatura;
  @override void initState() {
    super.initState();
    _controladorMiniatura = widget.esLocal 
        ? (kIsWeb ? VideoPlayerController.networkUrl(Uri.parse(widget.rutaVideo)) : VideoPlayerController.file(File(widget.rutaVideo)))
        : VideoPlayerController.asset(widget.rutaVideo);
    _controladorMiniatura.initialize().then((_) { _controladorMiniatura.setVolume(0.0); if(mounted) setState(() {}); }).catchError((_) {});
  }
  @override void dispose() { _controladorMiniatura.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return _controladorMiniatura.value.isInitialized
        ? Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controladorMiniatura.value.size.width, height: _controladorMiniatura.value.size.height, child: RepaintBoundary(child: Opacity(opacity: 0.99, child: VideoPlayer(_controladorMiniatura))))),
              Center(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Color(0xFFB89A6A).withOpacity(0.6), width: 1.5), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: -2)]), child: Icon(Icons.play_arrow_rounded, color: Color(0xFF6B2A2A), size: 30)))
            ],
          )
        : Container(color: Colors.black12, child: Center(child: CircularProgressIndicator(color: Color(0xFFB89A6A))));
  }
}

class ReproductorVideoControlesVintage extends StatefulWidget {
  final String rutaVideo;
  final bool esLocal;
  ReproductorVideoControlesVintage({required this.rutaVideo, this.esLocal = false});
  @override _ReproductorVideoControlesVintageState createState() => _ReproductorVideoControlesVintageState();
}

class _ReproductorVideoControlesVintageState extends State<ReproductorVideoControlesVintage> {
  late VideoPlayerController _controladorVideo;
  bool _tieneError = false;
  
  double? _valorArrastre; 
  bool _estaSilenciado = false; 

  @override void initState() {
    super.initState();
    try {
      _controladorVideo = widget.esLocal 
        ? (kIsWeb ? VideoPlayerController.networkUrl(Uri.parse(widget.rutaVideo)) : VideoPlayerController.file(File(widget.rutaVideo))) 
        : VideoPlayerController.asset(widget.rutaVideo);
      
      _controladorVideo.initialize().then((_) { 
        _controladorVideo.setLooping(true); 
        _controladorVideo.play(); 
        
        _controladorVideo.addListener(() {
          if (mounted && _valorArrastre == null) {
            setState(() {}); 
          }
        });
        
        if(mounted) setState(() {}); 
      });
    } catch (e) { if (mounted) setState(() => _tieneError = true); }
  }
  
  @override void dispose() { _controladorVideo.dispose(); super.dispose(); }
  
  String _formatearTiempo(Duration duracion) {
    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    return "${dosDigitos(duracion.inMinutes.remainder(60))}:${dosDigitos(duracion.inSeconds.remainder(60))}";
  }
  
  Widget _crearTornillo() {
    return Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFF8B6C42), Color(0xFF4A3515)]), border: Border.all(color: Colors.black38, width: 1), boxShadow: [BoxShadow(color: Colors.white24, offset: Offset(0.5, 0.5), blurRadius: 1)]), child: Center(child: Container(width: 6, height: 1, color: Colors.black45)));
  }

  void _retroceder10s() {
    final nuevaPos = _controladorVideo.value.position - Duration(seconds: 10);
    _controladorVideo.seekTo(nuevaPos < Duration.zero ? Duration.zero : nuevaPos);
  }

  void _adelantar10s() {
    final nuevaPos = _controladorVideo.value.position + Duration(seconds: 10);
    _controladorVideo.seekTo(nuevaPos > _controladorVideo.value.duration ? _controladorVideo.value.duration : nuevaPos);
  }

  void _reiniciarVideo() {
    _controladorVideo.seekTo(Duration.zero);
    _controladorVideo.play();
  }

  void _alternarSilencio() {
    setState(() {
      _estaSilenciado = !_estaSilenciado;
      _controladorVideo.setVolume(_estaSilenciado ? 0.0 : 1.0);
    });
  }

  @override Widget build(BuildContext context) {
    if (_tieneError) return Center(child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60));
    if (!_controladorVideo.value.isInitialized) return Center(child: CircularProgressIndicator(color: Color(0xFFB89A6A)));

    return Container(
      // Envolvemos todo el reproductor en la tarjeta dorada
      decoration: BoxDecoration(
        color: Color(0xFF2C241B), // Fondo oscuro por si el video no llena los bordes
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFB89A6A), width: 2), 
      ),
      child: Column(
        children: [
          // ¡EL ARREGLO FINAL! Usamos Expanded. 
          // Al video le decimos: "Toma TODO el espacio que sobre después de colocar los botones de abajo".
          // Así es IMPOSIBLE que haya overflow.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controladorVideo.value.aspectRatio, 
                  child: RepaintBoundary(child: Opacity(opacity: 0.99, child: ColorFiltered(colorFilter: matrizSepia, child: VideoPlayer(_controladorVideo))))
                ),
              ),
            ),
          ),
          
          // EL PANEL DE CONTROLES (Tamaño fijo)
          Container(
            height: 120, 
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFF6B2A2A), 
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border(top: BorderSide(color: Color(0xFFB89A6A), width: 2)) 
            ),
            child: Stack(
              children: [
                Positioned(top: 6, left: 6, child: _crearTornillo()), Positioned(top: 6, right: 6, child: _crearTornillo()), Positioned(bottom: 6, left: 6, child: _crearTornillo()), Positioned(bottom: 6, right: 6, child: _crearTornillo()),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(_formatearTiempo(_controladorVideo.value.position), style: GoogleFonts.greatVibes(fontSize: 22, color: Color(0xFFB89A6A), fontWeight: FontWeight.w500)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(activeTrackColor: Color(0xFFB89A6A), inactiveTrackColor: Colors.white24, thumbColor: Color(0xFFB89A6A), trackHeight: 3.0, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0)),
                              child: Slider(
                                value: _valorArrastre ?? _controladorVideo.value.position.inSeconds.toDouble().clamp(0.0, _controladorVideo.value.duration.inSeconds.toDouble()), 
                                min: 0.0, 
                                max: _controladorVideo.value.duration.inSeconds > 0 ? _controladorVideo.value.duration.inSeconds.toDouble() : 1.0, 
                                onChangeStart: (v) => setState(() => _valorArrastre = v),
                                onChanged: (v) => setState(() => _valorArrastre = v),
                                onChangeEnd: (v) {
                                  _controladorVideo.seekTo(Duration(seconds: v.toInt()));
                                  setState(() => _valorArrastre = null); 
                                },
                              ),
                            ),
                          ),
                          Text(_formatearTiempo(_controladorVideo.value.duration), style: GoogleFonts.greatVibes(fontSize: 22, color: Color(0xFFB89A6A), fontWeight: FontWeight.w500)),
                        ],
                      ),
                      
                      SizedBox(height: 5),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(_estaSilenciado ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Color(0xFFB89A6A), size: 28),
                            onPressed: _alternarSilencio,
                          ),
                          IconButton(
                            icon: Icon(Icons.replay_10_rounded, color: Color(0xFFB89A6A), size: 32),
                            onPressed: _retroceder10s,
                          ),
                          GestureDetector(
                            onTap: () { setState(() { _controladorVideo.value.isPlaying ? _controladorVideo.pause() : _controladorVideo.play(); }); },
                            child: Container(
                              height: 48, width: 48, 
                              decoration: BoxDecoration(color: Color(0xFFB89A6A), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black54, offset: Offset(2, 3), blurRadius: 4), BoxShadow(color: Colors.white30, offset: Offset(-1, -1), blurRadius: 2)]), 
                              child: Icon(_controladorVideo.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Color(0xFF6B2A2A), size: 32)
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.forward_10_rounded, color: Color(0xFFB89A6A), size: 32),
                            onPressed: _adelantar10s,
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, color: Color(0xFFB89A6A), size: 28),
                            onPressed: _reiniciarVideo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}