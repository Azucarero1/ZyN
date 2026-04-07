import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math';
import 'dart:io';

import '../core/notificaciones.dart';
import '../core/estado_global.dart'; 
import '../widgets/widgets_video.dart';
import 'detalle_album_screen.dart';

class PantallaGaleriaVintage extends StatefulWidget {
  @override _PantallaGaleriaVintageState createState() => _PantallaGaleriaVintageState();
}
class _PantallaGaleriaVintageState extends State<PantallaGaleriaVintage> {
  // Ahora usamos la lista que precargó el Splash Screen
  List<Map<String, String>> get _misRecuerdos => EstadoGlobal.misRecuerdos;
  
  final List<String> _miMusica = ["audio/Anhelo.mp3", "audio/Aventura.mp3", "audio/BabyBeMine.mp3", "audio/Inmortal.mp3", "audio/JuanLuisGuerra.mp3", "audio/LlévameContigo.mp3", "audio/Loco.mp3", "audio/LokitaPorMí.mp3", "audio/MICORAZONCITO.mp3", "audio/QueLocuraEnamorarmeDeTi.mp3"];
  final AudioPlayer _reproductorGlobal = AudioPlayer();
  int _indiceCancionActual = 0; 
  bool _estaReproduciendo = false; 
  bool _modoAleatorio = false; 
  bool _modoRepetir = false; 
  double _volumenGlobal = 0.8; 
  final ImagePicker _picker = ImagePicker(); 
  
  DateTime? _fechaReencuentro; 
  final ValueNotifier<String> _tiempoRestanteNotifier = ValueNotifier<String>("Configura la fecha ⚙️"); 
  Timer? _temporizador;

  @override void initState() {
    super.initState();
    _reproductorGlobal.setVolume(_volumenGlobal);
    _reproductorGlobal.onPlayerComplete.listen((event) { if (_modoRepetir) _reproducirMusica(_indiceCancionActual); else _siguienteCancion(); });
    _cargarFechaGuardada();
  }
  
  @override void dispose() { 
    _reproductorGlobal.dispose(); 
    _temporizador?.cancel(); 
    _tiempoRestanteNotifier.dispose(); 
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
      final XFile? arch = await _picker.pickMedia(imageQuality: 50);
      if (arch != null) {
        bool esVid = arch.path.toLowerCase().endsWith('.mp4') || arch.path.toLowerCase().endsWith('.mov') || arch.path.toLowerCase().endsWith('.avi');
        setState(() => EstadoGlobal.misRecuerdos.insert(0, {"tipo": esVid ? "video_local" : "foto_local", "archivo": arch.path}));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Añadido!"), backgroundColor: Color(0xFF6B2A2A)));
      }
    } catch (e) {
      print("Error al elegir imagen: $e");
    }
  }
  
  void _mostrarConfiguracion() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setModalState) => Container(decoration: BoxDecoration(color: Color(0xFFF4EFEA), borderRadius: BorderRadius.vertical(top: Radius.circular(25)), border: Border(top: BorderSide(color: Color(0xFFB89A6A), width: 3))), padding: EdgeInsets.symmetric(vertical: 25.0, horizontal: 20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text("Configuración", style: GoogleFonts.greatVibes(fontSize: 45, color: Color(0xFF6B2A2A))),
      ListTile(leading: Icon(Icons.hourglass_bottom_rounded, color: Color(0xFF6B2A2A), size: 30), title: Text("Día de nuestro encuentro", style: TextStyle(color: Color(0xFF6B2A2A), fontWeight: FontWeight.bold)), subtitle: Text("Toca para elegir la fecha", style: TextStyle(color: Color(0xFFB89A6A), fontStyle: FontStyle.italic)), onTap: () async { DateTime? sel = await showDatePicker(context: context, initialDate: _fechaReencuentro ?? DateTime.now().add(Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2030), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Color(0xFF6B2A2A), onPrimary: Colors.white, onSurface: Color(0xFF6B2A2A))), child: child!)); if (sel != null) { final prefs = await SharedPreferences.getInstance(); await prefs.setString('fecha_reencuentro', sel.toIso8601String()); setState(() { _fechaReencuentro = sel; _iniciarReloj(); }); Navigator.pop(context); } }),
      ListTile(leading: Icon(Icons.volume_up_rounded, color: Color(0xFF6B2A2A), size: 30), title: Text("Volumen de Música", style: TextStyle(color: Color(0xFF6B2A2A), fontWeight: FontWeight.bold)), subtitle: SliderTheme(data: SliderThemeData(activeTrackColor: Color(0xFFB89A6A), thumbColor: Color(0xFF6B2A2A)), child: Slider(value: _volumenGlobal, onChanged: (v) { setModalState(() => _volumenGlobal = v); setState(() => _volumenGlobal = v); _reproductorGlobal.setVolume(v); }))), 
      ListTile(
        leading: Icon(Icons.zoom_out_map_rounded, color: Color(0xFF6B2A2A), size: 30), 
        title: Text("Tamaño de la Galería", style: TextStyle(color: Color(0xFF6B2A2A), fontWeight: FontWeight.bold)), 
        subtitle: SliderTheme(
          data: SliderThemeData(activeTrackColor: Color(0xFFB89A6A), thumbColor: Color(0xFF6B2A2A)), 
          child: Slider(value: EstadoGlobal.escalaApp.value, min: 0.5, max: 1.5, onChanged: (v) { setModalState(() {}); EstadoGlobal.cambiarEscala(v); })
        )
      ), 
      SizedBox(height: 30)
    ]))));
  }
  
  void _reproducirMusica(int i) async { await _reproductorGlobal.stop(); await _reproductorGlobal.play(AssetSource(_miMusica[i])); setState(() { _indiceCancionActual = i; _estaReproduciendo = true; }); }
  void _pausarOPlay() async { if (_estaReproduciendo) { await _reproductorGlobal.pause(); setState(() => _estaReproduciendo = false); } else { await _reproductorGlobal.resume(); setState(() => _estaReproduciendo = true); } }
  void _siguienteCancion() { _reproducirMusica(_modoAleatorio ? Random().nextInt(_miMusica.length) : (_indiceCancionActual + 1) % _miMusica.length); }
  void _cancionAnterior() { _reproducirMusica((_indiceCancionActual - 1 + _miMusica.length) % _miMusica.length); }

  @override Widget build(BuildContext context) {
    final cT = Color(0xFF6B2A2A); final cB = Color(0xFFB89A6A); 
    double factorEscala = EstadoGlobal.escalaApp.value;
    int columnasCalculadas = (3 / factorEscala).round().clamp(1, 6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/MainBackground.jpg'), fit: BoxFit.cover)),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 5.0, left: 24, right: 16), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text('ZyN', style: GoogleFonts.greatVibes(fontSize: 50 * factorEscala, fontWeight: FontWeight.w600, color: cT)), 
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0), 
                    child: ValueListenableBuilder<String>(
                      valueListenable: _tiempoRestanteNotifier,
                      builder: (context, valorTiempo, child) {
                        return Text(
                          valorTiempo, 
                          textAlign: TextAlign.center, 
                          style: GoogleFonts.greatVibes(color: cT, fontSize: 18 * factorEscala, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)
                        );
                      }
                    )
                  )
                ), 
                Row(children: [ IconButton(icon: Icon(Icons.add_a_photo_outlined, color: cT, size: 28 * factorEscala), onPressed: _anadirRecuerdo), IconButton(icon: Icon(Icons.settings_outlined, color: cT, size: 28 * factorEscala), onPressed: _mostrarConfiguracion) ])
              ]
            )
          ),
          
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), 
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columnasCalculadas, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.85), 
              itemCount: _misRecuerdos.length, 
              itemBuilder: (context, index) {
                final rec = _misRecuerdos[index]; final tag = rec["archivo"]! + index.toString();
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PantallaDetalleAlbum(
                      recuerdos: _misRecuerdos, 
                      indiceInicial: index
                    )
                  )),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomRight: Radius.circular(30), topRight: Radius.circular(8), bottomLeft: Radius.circular(8)), border: Border.all(color: cB, width: 2.0), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 2))]), 
                    padding: EdgeInsets.all(4), 
                    child: Hero(tag: tag, child: ClipRRect(borderRadius: BorderRadius.only(topLeft: Radius.circular(26), bottomRight: Radius.circular(26), topRight: Radius.circular(4), bottomLeft: Radius.circular(4)), child: ColorFiltered(colorFilter: ColorFilter.matrix([0.9, 0.1, 0.05, 0, 0, 0.1, 0.8, 0.05, 0, 0, 0.1, 0.1, 0.75, 0, 0, 0, 0, 0, 1, 0]), child: _crearMiniatura(rec))))
                  ),
                );
              }
            )
          ),
          
          Container(
            padding: EdgeInsets.only(top: 15, bottom: 25, left: 15, right: 15), color: Colors.white.withOpacity(0.75), 
            child: Column(
              mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.music_note, size: 16 * factorEscala, color: cB), SizedBox(width: 8), Text(_estaReproduciendo ? _miMusica[_indiceCancionActual].split('/').last.replaceAll('.mp3', '') : "Presiona Play", style: GoogleFonts.greatVibes(color: cT, fontSize: 18 * factorEscala, fontWeight: FontWeight.w600)), SizedBox(width: 8), Icon(Icons.music_note, size: 16 * factorEscala, color: cB) ]),
                SizedBox(height: 12), 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ 
                    IconButton(icon: Icon(Icons.shuffle, color: _modoAleatorio ? cT : cB, size: 24 * factorEscala), onPressed: () => setState(() => _modoAleatorio = !_modoAleatorio)), 
                    IconButton(iconSize: 35 * factorEscala, icon: Icon(Icons.skip_previous_rounded, color: cT), onPressed: _cancionAnterior), 
                    GestureDetector(onTap: _estaReproduciendo ? _pausarOPlay : () => _reproducirMusica(_indiceCancionActual), child: Icon(_estaReproduciendo ? Icons.pause_rounded : Icons.play_arrow_rounded, color: cT, size: 50 * factorEscala)), 
                    IconButton(iconSize: 35 * factorEscala, icon: Icon(Icons.skip_next_rounded, color: cT), onPressed: _siguienteCancion), 
                    IconButton(icon: Icon(Icons.repeat, color: _modoRepetir ? cT : cB, size: 24 * factorEscala), onPressed: () => setState(() => _modoRepetir = !_modoRepetir)) 
                  ]
                )
              ]
            )
          )
        ])),
      ),
    );
  }
  
  Widget _crearMiniatura(Map<String, String> rec) {
    // Al usar ResizeImage obligamos a Flutter a consumir la versión liviana que guardó en RAM el Splash Screen.
    if (rec["tipo"] == "foto") {
      return Image(image: ResizeImage(AssetImage(rec["archivo"]!), width: 300), fit: BoxFit.cover);
    }
    if (rec["tipo"] == "foto_local") {
      return kIsWeb 
          ? Image.network(rec["archivo"]!, fit: BoxFit.cover) 
          : Image(image: ResizeImage(FileImage(File(rec["archivo"]!)), width: 300), fit: BoxFit.cover);
    }
    return IgnorePointer(child: MiniaturaVideoAutomatica(key: ValueKey(rec["archivo"]), rutaVideo: rec["archivo"]!, esLocal: rec["tipo"] == "video_local"));
  }
}