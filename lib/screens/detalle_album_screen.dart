import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart'; 
import 'dart:io';

import '../widgets/widgets_video.dart'; 

class PantallaDetalleAlbum extends StatefulWidget {
  final List<Map<String, String>> recuerdos;
  final int indiceInicial;

  const PantallaDetalleAlbum({Key? key, required this.recuerdos, required this.indiceInicial}) : super(key: key);

  @override
  State<PantallaDetalleAlbum> createState() => _PantallaDetalleAlbumState();
}

class _PantallaDetalleAlbumState extends State<PantallaDetalleAlbum>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recuerdos = widget.recuerdos;
    final indiceInicial = widget.indiceInicial;

    PageController controladorPaginas = PageController(initialPage: indiceInicial);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFB89A6A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      extendBodyBehindAppBar: true, 
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/MainBackground.jpg'), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0xFF1A0F0A).withOpacity(0.85), 
              BlendMode.darken, 
            ),
          ),
        ),
        // SafeArea protege que el contenido no choque con el notch o botones del celular
        child: SafeArea( 
          child: PageView.builder(
            controller: controladorPaginas,
            itemCount: recuerdos.length,
            itemBuilder: (context, index) {
              final recuerdoActual = recuerdos[index];
              final tagAnimacion = '${recuerdoActual["archivo"]}-$index';
              bool esVideo = recuerdoActual["tipo"] == "video" || recuerdoActual["tipo"] == "video_local";

              return FadeTransition(
                opacity: _fadeAnimation,
                child: esVideo
                    ? _construirVistaVideo(context, recuerdoActual, tagAnimacion)
                    : _construirVistaFoto(context, recuerdoActual, tagAnimacion),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _esquinaRomantica(double? top, double? left, double? bottom, double? right) {
    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? BorderSide(color: Color(0xFFB89A6A), width: 3) : BorderSide.none,
            left: left != null ? BorderSide(color: Color(0xFFB89A6A), width: 3) : BorderSide.none,
            bottom: bottom != null ? BorderSide(color: Color(0xFFB89A6A), width: 3) : BorderSide.none,
            right: right != null ? BorderSide(color: Color(0xFFB89A6A), width: 3) : BorderSide.none,
          ),
        ),
        child: Align(
          alignment: top != null && left != null ? Alignment.topLeft :
                     top != null && right != null ? Alignment.topRight :
                     bottom != null && left != null ? Alignment.bottomLeft :
                     Alignment.bottomRight,
          child: Container(
            margin: EdgeInsets.all(4), width: 8, height: 8,
            decoration: BoxDecoration(color: Color(0xFF6B2A2A), shape: BoxShape.circle, border: Border.all(color: Color(0xFFB89A6A), width: 1.5))
          )
        )
      )
    );
  }

  Widget _construirVistaFoto(BuildContext context, Map<String, String> recuerdo, String tagAnimacion) {
    Widget fotoVisual = recuerdo["tipo"] == "foto"
        ? Image.asset(recuerdo["archivo"]!, fit: BoxFit.contain)
        : (kIsWeb ? Image.network(recuerdo["archivo"]!, fit: BoxFit.contain) : Image.file(File(recuerdo["archivo"]!), fit: BoxFit.contain));

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        // EL ARREGLO: Límite estricto de altura (80% de la pantalla)
        height: MediaQuery.of(context).size.height * 0.80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Expanded hace que la foto tome exactamente el espacio disponible sin desbordar
            Expanded( 
              child: Container(
                padding: EdgeInsets.all(12), 
                decoration: BoxDecoration(
                  color: Color(0xFF6B2A2A), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFFB89A6A), width: 2), 
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))] 
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Hero(
                        tag: tagAnimacion,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: ColorFiltered(
                            colorFilter: matrizSepia,
                            child: fotoVisual, 
                          ),
                        ),
                      ),
                    ),
                    _esquinaRomantica(12, 12, null, null), 
                    _esquinaRomantica(12, null, null, 12), 
                    _esquinaRomantica(null, 12, 12, null), 
                    _esquinaRomantica(null, null, 12, 12), 
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: Text(
                    "Para siempre...",
                    style: GoogleFonts.greatVibes(
                      fontSize: 42,
                      color: const Color(0xFFE8D4A8),
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF6B2A2A).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVistaVideo(BuildContext context, Map<String, String> recuerdo, String tagAnimacion) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        // CAJA FUERTE: Fijamos la altura al 80% de la pantalla. El reproductor de adentro tendrá que encogerse sí o sí.
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 15))
          ]
        ),
        child: Hero(
          tag: tagAnimacion,
          child: ReproductorVideoControlesVintage(
            rutaVideo: recuerdo["archivo"]!, 
            esLocal: recuerdo["tipo"] == "video_local"
          ),
        ),
      ),
    );
  }
}