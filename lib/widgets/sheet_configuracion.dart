import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/estado_global.dart';
import '../core/theme.dart';

/// Modal con la configuración del usuario:
/// fecha de reencuentro, volumen y escala de la galería.
///
/// Las preferencias se guardan automáticamente al cambiarlas, sin botones.
class SheetConfiguracion extends StatefulWidget {
  final DateTime? fechaReencuentro;
  final ValueChanged<DateTime> onFechaChanged;

  const SheetConfiguracion({
    super.key,
    required this.fechaReencuentro,
    required this.onFechaChanged,
  });

  @override
  State<SheetConfiguracion> createState() => _SheetConfiguracionState();
}

class _SheetConfiguracionState extends State<SheetConfiguracion> {
  static const _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: widget.fechaReencuentro ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.granate,
            onPrimary: Colors.white,
            onSurface: AppColors.granate,
          ),
        ),
        child: child!,
      ),
    );
    if (seleccion != null) {
      await EstadoGlobal.guardarFechaReencuentro(seleccion);
      widget.onFechaChanged(seleccion);
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatearFecha(DateTime f) =>
      '${f.day} ${_meses[f.month - 1]} ${f.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cremaSuave, AppColors.cremaPiedra],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.oro, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre.
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.oro.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Configuración',
              style: GoogleFonts.greatVibes(
                fontSize: 44,
                color: AppColors.granate,
                shadows: [
                  Shadow(
                    color: AppColors.oro.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Filete decorativo bajo el título.
            Container(
              width: 90,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.oro.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _OpcionConfig(
              icon: Icons.calendar_month_rounded,
              title: 'Día de nuestro encuentro',
              subtitle: widget.fechaReencuentro != null
                  ? _formatearFecha(widget.fechaReencuentro!)
                  : 'Toca para elegir la fecha',
              onTap: _seleccionarFecha,
            ),
            const SizedBox(height: 10),
            const _OpcionVolumen(),
            const SizedBox(height: 10),
            const _OpcionEscala(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OpcionVolumen extends StatelessWidget {
  const _OpcionVolumen();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: EstadoGlobal.volumenMusica,
      builder: (_, volumen, __) => _OpcionConfig(
        icon: volumen > 0
            ? (volumen > 0.5
                ? Icons.volume_up_rounded
                : Icons.volume_down_rounded)
            : Icons.volume_off_rounded,
        title: 'Volumen de Música',
        subtitle: '${(volumen * 100).round()}%',
        trailing: SizedBox(
          width: 110,
          child: _SliderVintage(
            value: volumen,
            onChanged: EstadoGlobal.cambiarVolumen,
          ),
        ),
      ),
    );
  }
}

class _OpcionEscala extends StatelessWidget {
  const _OpcionEscala();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: EstadoGlobal.escalaApp,
      builder: (_, escala, __) => _OpcionConfig(
        icon: Icons.aspect_ratio_rounded,
        title: 'Tamaño de la Interfaz',
        subtitle: '${(escala * 100).round()}%',
        trailing: SizedBox(
          width: 110,
          child: _SliderVintage(
            value: escala,
            min: 0.7,
            max: 1.4,
            onChanged: EstadoGlobal.cambiarEscala,
          ),
        ),
      ),
    );
  }
}

class _SliderVintage extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderVintage({
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp por si el valor persistido cae fuera del nuevo rango (defensivo).
    final clamped = value.clamp(min, max);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.oro,
        inactiveTrackColor: AppColors.oro.withOpacity(0.25),
        thumbColor: AppColors.granate,
        overlayColor: AppColors.oro.withOpacity(0.18),
        trackHeight: 4,
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 9,
          elevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      child: Slider(
        value: clamped,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}

class _OpcionConfig extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _OpcionConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.oro.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.oro.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.granate, AppColors.granateOscuro],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.granate.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.oroClaro, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.granate,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.oro.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.oro),
            ],
          ),
        ),
      ),
    );
  }
}
