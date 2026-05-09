import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tarjeta de la galería con efecto de presión y borde dorado vintage.
/// El contenido se aplica con filtro sepia para mantener el tono romántico.
class TarjetaRecuerdo extends StatefulWidget {
  final String tag;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const TarjetaRecuerdo({
    super.key,
    required this.tag,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  @override
  State<TarjetaRecuerdo> createState() => _TarjetaRecuerdoState();
}

class _TarjetaRecuerdoState extends State<TarjetaRecuerdo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.78),
                  Colors.white.withOpacity(0.55),
                ],
              ),
              // Esquinas asimétricas (estilo polaroid vintage) más sutiles.
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              border: Border.all(
                color: AppColors.oro.withOpacity(0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.granate.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.45),
                  blurRadius: 6,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Hero(
              tag: widget.tag,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                child: ColorFiltered(
                  colorFilter: matrizSepia,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
