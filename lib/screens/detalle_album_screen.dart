import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/estado_global.dart';
import '../core/theme.dart';
import '../widgets/widgets_video.dart';

/// Vista a pantalla completa de un recuerdo (foto o video) con
/// transiciones Hero desde la galería.
class PantallaDetalleAlbum extends StatefulWidget {
  final List<Recuerdo> recuerdos;
  final int indiceInicial;

  const PantallaDetalleAlbum({
    super.key,
    required this.recuerdos,
    required this.indiceInicial,
  });

  @override
  State<PantallaDetalleAlbum> createState() => _PantallaDetalleAlbumState();
}

class _PantallaDetalleAlbumState extends State<PantallaDetalleAlbum>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.indiceInicial);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.oro),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/MainBackground.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppColors.granateNoche.withOpacity(0.85),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.recuerdos.length,
            itemBuilder: (context, index) {
              final r = widget.recuerdos[index];
              final tag = '${r.archivo}-$index';
              return FadeTransition(
                opacity: _fadeAnimation,
                child: r.tipo.esVideo
                    ? _VistaVideo(recuerdo: r, tag: tag)
                    : _VistaFoto(recuerdo: r, tag: tag),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VistaFoto extends StatelessWidget {
  final Recuerdo recuerdo;
  final String tag;

  const _VistaFoto({required this.recuerdo, required this.tag});

  Widget _imagen() {
    if (recuerdo.tipo == TipoMedio.fotoAsset) {
      return Image.asset(recuerdo.archivo, fit: BoxFit.contain);
    }
    if (kIsWeb) {
      return Image.network(recuerdo.archivo, fit: BoxFit.contain);
    }
    return Image.file(File(recuerdo.archivo), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.granate,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.oro, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Hero(
                        tag: tag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: ColorFiltered(
                            colorFilter: matrizSepia,
                            child: _imagen(),
                          ),
                        ),
                      ),
                    ),
                    const _EsquinaRomantica(top: 12, left: 12),
                    const _EsquinaRomantica(top: 12, right: 12),
                    const _EsquinaRomantica(bottom: 12, left: 12),
                    const _EsquinaRomantica(bottom: 12, right: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _PieDePagina(),
          ],
        ),
      ),
    );
  }
}

class _PieDePagina extends StatelessWidget {
  const _PieDePagina();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Text(
            'Para siempre…',
            style: GoogleFonts.greatVibes(
              fontSize: 42,
              color: AppColors.oroClaro,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: AppColors.granate.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VistaVideo extends StatelessWidget {
  final Recuerdo recuerdo;
  final String tag;

  const _VistaVideo({required this.recuerdo, required this.tag});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: SizedBox(
        width: size.width * 0.95,
        height: size.height * 0.80,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 25,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Hero(
            tag: tag,
            child: ReproductorVideoControlesVintage(
              rutaVideo: recuerdo.archivo,
              esLocal: recuerdo.tipo == TipoMedio.videoLocal,
            ),
          ),
        ),
      ),
    );
  }
}

class _EsquinaRomantica extends StatelessWidget {
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;

  const _EsquinaRomantica({this.top, this.left, this.bottom, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: AppColors.oro, width: 3)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: AppColors.oro, width: 3)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: AppColors.oro, width: 3)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: AppColors.oro, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Align(
          alignment: top != null && left != null
              ? Alignment.topLeft
              : top != null && right != null
                  ? Alignment.topRight
                  : bottom != null && left != null
                      ? Alignment.bottomLeft
                      : Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.granate,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.oro, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
