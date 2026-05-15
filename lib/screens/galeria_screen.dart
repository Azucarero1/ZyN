import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart' as picker show ImageSource;
import 'package:simple_gradient_text/simple_gradient_text.dart';

import '../core/estado_global.dart';
import '../core/notificaciones.dart';
import '../core/theme.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/petalos_animados.dart';
import '../widgets/reproductor_vintage.dart';
import '../widgets/sheet_configuracion.dart';
import '../widgets/tarjeta_recuerdo.dart';
import '../widgets/widgets_video.dart';
import 'carta_screen.dart';
import 'detalle_album_screen.dart';
import 'jardin_screen.dart';

/// Lista de canciones empaquetadas como assets. El orden define la lista
/// de reproducción "en serie"; el modo aleatorio elige al azar.
const List<String> _miMusica = [
  'audio/Anhelo.mp3',
  'audio/Aventura.mp3',
  'audio/BabyBeMine.mp3',
  'audio/Inmortal.mp3',
  'audio/JuanLuisGuerra.mp3',
  'audio/LlévameContigo.mp3',
  'audio/Loco.mp3',
  'audio/LokitaPorMí.mp3',
  'audio/MICORAZONCITO.mp3',
  'audio/QueLocuraEnamorarmeDeTi.mp3',
  'audio/QueSeMueran.mp3',
  'audio/Quepreciotieneelcielo.mp3',
  'audio/TuAmorMeHaceBien.mp3',
  'audio/Tuyo.mp3',
];

/// Pantalla principal: galería de fotos/videos + reproductor vintage anclado.
class PantallaGaleriaVintage extends StatefulWidget {
  const PantallaGaleriaVintage({super.key});

  @override
  State<PantallaGaleriaVintage> createState() =>
      _PantallaGaleriaVintageState();
}

class _PantallaGaleriaVintageState extends State<PantallaGaleriaVintage> {
  final AudioPlayer _reproductorGlobal = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  final ValueNotifier<int> _indiceCancion = ValueNotifier<int>(0);
  final ValueNotifier<bool> _estaReproduciendo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _modoAleatorio = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _modoRepetir = ValueNotifier<bool>(false);

  DateTime? _fechaReencuentro;
  final ValueNotifier<String> _tiempoRestante =
      ValueNotifier<String>('Configura la fecha ⚙️');
  Timer? _temporizador;

  // Para evitar enviar la misma alerta múltiples veces dentro del mismo segundo.
  int _ultimoDiaAlertado = -1;

  StreamSubscription<void>? _completionSub;
  VoidCallback? _volumenListener;

  // Control del PageView galería ↔ jardín.
  final PageController _pageController = PageController();
  final ValueNotifier<int> _paginaActual = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _reproductorGlobal.setVolume(EstadoGlobal.volumenMusica.value);
    _completionSub = _reproductorGlobal.onPlayerComplete.listen((_) {
      if (_modoRepetir.value) {
        _reproducir(_indiceCancion.value);
      } else {
        _siguienteCancion();
      }
    });
    _volumenListener = () =>
        _reproductorGlobal.setVolume(EstadoGlobal.volumenMusica.value);
    EstadoGlobal.volumenMusica.addListener(_volumenListener!);

    _fechaReencuentro = EstadoGlobal.fechaReencuentro;
    if (_fechaReencuentro != null) _iniciarReloj();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _completionSub?.cancel();
    if (_volumenListener != null) {
      EstadoGlobal.volumenMusica.removeListener(_volumenListener!);
    }
    _reproductorGlobal.dispose();
    _tiempoRestante.dispose();
    _indiceCancion.dispose();
    _estaReproduciendo.dispose();
    _modoAleatorio.dispose();
    _modoRepetir.dispose();
    _pageController.dispose();
    _paginaActual.dispose();
    super.dispose();
  }

  void _iniciarReloj() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      final fecha = _fechaReencuentro;
      if (fecha == null) return;
      final diff = fecha.difference(DateTime.now());
      if (diff.isNegative) {
        _tiempoRestante.value = '¡Hoy es el gran día! ❤️';
        timer.cancel();
        return;
      }
      final d = diff.inDays;
      final h = diff.inHours % 24;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;

      // Notificaciones diarias en hitos (y solo una vez por día).
      if (d != _ultimoDiaAlertado && h == 0 && m == 0 && s == 0) {
        _ultimoDiaAlertado = d;
        if (d == 7) {
          notificar(
            id: IdsNotificacion.unaSemana,
            titulo: '¡Falta 1 semana! ⏳',
            cuerpo: 'Ya casi estamos juntos.',
          );
        } else if (d == 1) {
          notificar(
            id: IdsNotificacion.unDia,
            titulo: '¡Mañana nos vemos! 😍',
            cuerpo: 'Prepara abrazos.',
          );
        }
      }
      _tiempoRestante.value = 'Faltan $d d, $h h, $m m, $s s';
    });
  }

  Future<void> _anadirRecuerdo() async {
    final origen = await _elegirTipoMedio();
    if (origen == null || !mounted) return;

    try {
      final nuevos = await _seleccionarMedios(origen);
      if (nuevos.isEmpty) return;
      await EstadoGlobal.agregarRecuerdos(nuevos);
      if (!mounted) return;
      _mostrarSnack('¡${nuevos.length} ${nuevos.length == 1 ? "recuerdo añadido" : "recuerdos añadidos"}!');
    } catch (e) {
      debugPrint('Error al añadir recuerdo: $e');
      if (mounted) _mostrarSnack('No pude leer ese archivo 😔');
    }
  }

  Future<_TipoSeleccion?> _elegirTipoMedio() {
    return showModalBottomSheet<_TipoSeleccion>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cremaSuave, AppColors.cremaPiedra],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.oro, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.oro.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Añadir Recuerdo',
                style: GoogleFonts.greatVibes(
                  fontSize: 36,
                  color: AppColors.granate,
                ),
              ),
              const SizedBox(height: 16),
              _OpcionMedioTile(
                icon: Icons.perm_media_outlined,
                titulo: 'Fotos y videos',
                subtitulo: 'Selecciona varios al mismo tiempo',
                onTap: () => Navigator.pop(ctx, _TipoSeleccion.mixto),
              ),
              const SizedBox(height: 10),
              _OpcionMedioTile(
                icon: Icons.photo_camera_outlined,
                titulo: 'Tomar una foto',
                subtitulo: 'Captura un momento ahora',
                onTap: () => Navigator.pop(ctx, _TipoSeleccion.camara),
              ),
              const SizedBox(height: 10),
              _OpcionMedioTile(
                icon: Icons.videocam_outlined,
                titulo: 'Grabar un video',
                subtitulo: 'Captura un video con la cámara',
                onTap: () => Navigator.pop(ctx, _TipoSeleccion.videoCamara),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Recuerdo>> _seleccionarMedios(_TipoSeleccion origen) async {
    switch (origen) {
      case _TipoSeleccion.mixto:
        // pickMultipleMedia permite seleccionar fotos y videos simultáneamente
        // sin límite, devolviendo una lista mezclada de XFile.
        final archivos = await _picker.pickMultipleMedia(imageQuality: 60);
        return archivos.map(_clasificar).toList(growable: false);
      case _TipoSeleccion.camara:
        final foto = await _picker.pickImage(
          source: picker.ImageSource.camera,
          imageQuality: 70,
        );
        if (foto == null) return const [];
        return [Recuerdo(tipo: TipoMedio.fotoLocal, archivo: foto.path)];
      case _TipoSeleccion.videoCamara:
        final video = await _picker.pickVideo(
          source: picker.ImageSource.camera,
          maxDuration: const Duration(minutes: 5),
        );
        if (video == null) return const [];
        return [Recuerdo(tipo: TipoMedio.videoLocal, archivo: video.path)];
    }
  }

  Recuerdo _clasificar(XFile archivo) {
    final p = archivo.path.toLowerCase();
    final esVideo = p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.avi');
    return Recuerdo(
      tipo: esVideo ? TipoMedio.videoLocal : TipoMedio.fotoLocal,
      archivo: archivo.path,
    );
  }

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.granate,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarConfiguracion() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SheetConfiguracion(
        fechaReencuentro: _fechaReencuentro,
        onFechaChanged: (fecha) {
          setState(() {
            _fechaReencuentro = fecha;
            _ultimoDiaAlertado = -1;
            _iniciarReloj();
          });
        },
      ),
    );
  }

  /// Reproduce desde el inicio una canción del índice [i].
  /// Se usa al cambiar de pista (siguiente/anterior) o al elegir
  /// explícitamente una canción nueva.
  Future<void> _reproducir(int i) async {
    await _reproductorGlobal.stop();
    await _reproductorGlobal.play(AssetSource(_miMusica[i]));
    _indiceCancion.value = i;
    _estaReproduciendo.value = true;
  }

  /// Alterna play/pause **conservando la posición actual de la pista**.
  ///
  /// - Si está reproduciendo → pausa.
  /// - Si está pausado y hay una pista cargada → `resume()` desde el
  ///   `currentTime` exacto donde quedó.
  /// - Si nunca se ha reproducido nada (estado inicial) → arranca la
  ///   pista actual desde el inicio.
  Future<void> _pausarOPlay() async {
    if (_estaReproduciendo.value) {
      await _reproductorGlobal.pause();
      _estaReproduciendo.value = false;
      return;
    }

    final estado = _reproductorGlobal.state;
    if (estado == PlayerState.paused) {
      // Continúa desde donde quedó (currentTime preservado por el motor nativo).
      await _reproductorGlobal.resume();
    } else {
      // Sin pista cargada: arranca la canción seleccionada desde el inicio.
      await _reproductorGlobal.play(AssetSource(_miMusica[_indiceCancion.value]));
    }
    _estaReproduciendo.value = true;
  }

  void _siguienteCancion() {
    final nuevo = _modoAleatorio.value
        ? Random().nextInt(_miMusica.length)
        : (_indiceCancion.value + 1) % _miMusica.length;
    _reproducir(nuevo);
  }

  void _cancionAnterior() {
    final nuevo =
        (_indiceCancion.value - 1 + _miMusica.length) % _miMusica.length;
    _reproducir(nuevo);
  }

  void _abrirCarta() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const PantallaCarta(),
        transitionsBuilder: (_, animacion, __, child) => FadeTransition(
          opacity: animacion,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animacion, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PageView horizontal con dos páginas:
      //  · Página 0: la galería (foto-vinilo + reproductor)
      //  · Página 1: el Jardín del Amor
      // Deslizar hacia la izquierda revela el jardín, deslizar hacia la
      // derecha vuelve a la galería. La música sigue sonando en ambas.
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (i) => _paginaActual.value = i,
        children: [
          _construirGaleria(),
          const PantallaJardin(),
        ],
      ),
    );
  }

  /// Construye la página de la galería (background + petalos + contenido).
  Widget _construirGaleria() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo de mármol vintage.
        const DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/MainBackground.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Capa decorativa: pétalos cayendo en bucle infinito.
        // Solo en la galería principal — no afecta a otras pantallas.
        const Positioned.fill(
          child: PetalosAnimados(densidad: 16),
        ),
        // Contenido principal.
        SafeArea(
          child: Column(
            children: [
              _Encabezado(
                tiempoRestante: _tiempoRestante,
                onAnadir: _anadirRecuerdo,
                onConfigurar: _mostrarConfiguracion,
                onAbrirCarta: _abrirCarta,
              ),
              const Expanded(child: _Galeria()),
              ValueListenableBuilder<double>(
                valueListenable: EstadoGlobal.escalaApp,
                builder: (_, factor, __) => ReproductorRadioVintage(
                  factorEscala: factor,
                  indiceCancionNotifier: _indiceCancion,
                  estaReproduciendoNotifier: _estaReproduciendo,
                  modoAleatorioNotifier: _modoAleatorio,
                  modoRepetirNotifier: _modoRepetir,
                  miMusica: _miMusica,
                  onPlayPause: _pausarOPlay,
                  onNext: _siguienteCancion,
                  onPrevious: _cancionAnterior,
                  onToggleAleatorio: () =>
                      _modoAleatorio.value = !_modoAleatorio.value,
                  onToggleRepetir: () =>
                      _modoRepetir.value = !_modoRepetir.value,
                  reproductor: _reproductorGlobal,
                ),
              ),
            ],
          ),
        ),
        // Indicador "desliza para ir al jardín" en el borde derecho.
        // Solo visible mientras la página activa es la 0 (galería).
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: ValueListenableBuilder<int>(
            valueListenable: _paginaActual,
            builder: (_, pagina, __) => IgnorePointer(
              child: AnimatedOpacity(
                opacity: pagina == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: const _IndicadorJardin(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _TipoSeleccion { mixto, camara, videoCamara }

/// Tile estilizado para el modal de selección de medios.
class _OpcionMedioTile extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _OpcionMedioTile({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.oro.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.granate,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.oro, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.granate,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.oro.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.oro),
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final ValueNotifier<String> tiempoRestante;
  final VoidCallback onAnadir;
  final VoidCallback onConfigurar;
  final VoidCallback onAbrirCarta;

  const _Encabezado({
    required this.tiempoRestante,
    required this.onAnadir,
    required this.onConfigurar,
    required this.onAbrirCarta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF26B2A2A),
            Color(0xF24A1A1A),
            Color(0xF22A1515),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.oro.withOpacity(0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.granate.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.oro.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo "ZyN" con gradiente dorado.
        Container(
            child: GradientText(
              'ZyN ',
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ), 
    colors: [
        AppColors.oroClaro,
        const Color.fromARGB(188, 232, 212, 168),
        const Color.fromARGB(162, 232, 212, 168),
    ],
              
            ),
          ),
          // Pastilla con la cuenta regresiva.
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.granateProfundo.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.oro.withOpacity(0.35),
                ),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: tiempoRestante,
                builder: (_, valor, __) => Text(
                  valor,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    color: AppColors.oroClaro,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
          _BotonHeader(
            icon: Icons.mail_outline_rounded,
            onPressed: onAbrirCarta,
            // Pulsa suavemente para invitar a abrir la carta.
            pulsoSuave: true,
          ),
          const SizedBox(width: 6),
          _BotonHeader(
            icon: Icons.add_a_photo_outlined,
            onPressed: onAnadir,
          ),
          const SizedBox(width: 6),
          _BotonHeader(
            icon: Icons.settings_outlined,
            onPressed: onConfigurar,
          ),
        ],
      ),
    );
  }
}

class _BotonHeader extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  /// Si es true, el botón emite un pulso dorado suave en bucle para
  /// invitar al usuario a tocarlo (útil para acciones especiales como
  /// "abrir carta").
  final bool pulsoSuave;

  const _BotonHeader({
    required this.icon,
    required this.onPressed,
    this.pulsoSuave = false,
  });

  @override
  State<_BotonHeader> createState() => _BotonHeaderState();
}

class _BotonHeaderState extends State<_BotonHeader>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulso;

  @override
  void initState() {
    super.initState();
    if (widget.pulsoSuave) {
      _pulso = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulso?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boton = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.oro.withOpacity(0.22),
                AppColors.oro.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.oro.withOpacity(0.45)),
          ),
          child: Icon(widget.icon, color: AppColors.oroClaro, size: 22),
        ),
      ),
    );

    if (_pulso == null) return boton;
    // Capa de glow pulsante alrededor del botón.
    return AnimatedBuilder(
      animation: _pulso!,
      builder: (_, __) {
        final v = _pulso!.value; // 0..1
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.oro.withOpacity(0.15 + v * 0.35),
                blurRadius: 8 + v * 14,
                spreadRadius: -1,
              ),
            ],
          ),
          child: boton,
        );
      },
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: EstadoGlobal.escalaApp,
      builder: (_, factor, __) => ValueListenableBuilder<List<Recuerdo>>(
        valueListenable: EstadoGlobal.recuerdos,
        builder: (_, recuerdos, __) {
          if (recuerdos.isEmpty) {
            return EstadoVacioVintage(factorEscala: factor);
          }

          // Calcula el ancho máximo de cada tarjeta en función del
          // factor de escala. Así el grid se reorganiza fluidamente sin
          // saltos bruscos de columna.
          final tileMax = 130.0 * factor;
          return GridView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            cacheExtent: 200.0,
            addAutomaticKeepAlives: false,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: tileMax,
              crossAxisSpacing: 14.0,
              mainAxisSpacing: 14.0,
              childAspectRatio: 0.82,
            ),
            itemCount: recuerdos.length,
            itemBuilder: (context, index) {
              final r = recuerdos[index];
              final tag = '${r.archivo}-$index';
              return TarjetaRecuerdo(
                tag: tag,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaDetalleAlbum(
                      recuerdos: recuerdos,
                      indiceInicial: index,
                    ),
                  ),
                ),
                onLongPress: () => _confirmarEliminar(context, r),
                child: _Miniatura(recuerdo: r),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Recuerdo r) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cremaSuave,
        title: Text(
          '¿Borrar este recuerdo?',
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.granate,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: GoogleFonts.cormorantGaramond(color: AppColors.granate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.granate.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () {
              EstadoGlobal.eliminarRecuerdo(r);
              Navigator.pop(ctx);
            },
            child: const Text('Borrar',
                style: TextStyle(
                    color: AppColors.granate, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final Recuerdo recuerdo;

  const _Miniatura({required this.recuerdo});

  @override
  Widget build(BuildContext context) {
    switch (recuerdo.tipo) {
      case TipoMedio.fotoAsset:
        return Image(
          image: ResizeImage(AssetImage(recuerdo.archivo), width: 300),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      case TipoMedio.fotoLocal:
        if (kIsWeb) {
          return Image.network(
            recuerdo.archivo,
            fit: BoxFit.cover,
            cacheWidth: 300,
          );
        }
        return Image(
          image: ResizeImage(FileImage(File(recuerdo.archivo)), width: 300),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      case TipoMedio.videoAsset:
      case TipoMedio.videoLocal:
        return IgnorePointer(
          child: MiniaturaVideoAutomatica(
            key: ValueKey(recuerdo.archivo),
            rutaVideo: recuerdo.archivo,
            esLocal: recuerdo.tipo == TipoMedio.videoLocal,
          ),
        );
    }
  }
}

/// Indicador discreto en el borde derecho de la galería que invita a
/// deslizar hacia el Jardín del Amor. Es una pequeña flor de jazmín que
/// pulsa con suavidad, junto a un filete dorado vertical.
class _IndicadorJardin extends StatefulWidget {
  const _IndicadorJardin();

  @override
  State<_IndicadorJardin> createState() => _IndicadorJardinState();
}

class _IndicadorJardinState extends State<_IndicadorJardin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulso,
          builder: (_, __) {
            // Mueve un par de píxeles hacia la izquierda para sugerir
            // dirección del swipe ("ven a verme").
            final offset = -4 - _pulso.value * 6;
            final opacidadFlor = 0.45 + _pulso.value * 0.35;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🌸',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withValues(alpha: opacidadFlor),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Filete vertical dorado que se desvanece arriba/abajo.
                  Container(
                    width: 1.2,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.oro.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
