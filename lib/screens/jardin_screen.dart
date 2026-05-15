import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/estado_jardin.dart';
import '../core/theme.dart';
import '../widgets/animacion_recoleccion.dart';
import '../widgets/animacion_riego.dart';
import '../widgets/fondo_jardin.dart';
import '../widgets/jardin_painter.dart';
import '../widgets/luciernagas_animadas.dart';
import '../widgets/maceta_imagen.dart';
import '../widgets/tutorial_jardin.dart';

/// Pantalla del Jardín del Amor.
///
/// Composición:
///  · Fondo: imagen de jardín botánico victoriano (día/atardecer/noche
///    según la hora real). La imagen YA INCLUYE la mesita vintage donde
///    se apoya la maceta.
///  · Encima de la mesa de la imagen: la maceta + jazmín dibujados con
///    `CustomPaint`. La base de la maceta se alinea con el tablero de
///    la mesa de la foto.
///  · Título top-left con backdrop, badge top-right.
///  · Pestaña-flecha en el borde derecho que abre un panel deslizable
///    con racha / ramo / cumpleaños.
///  · Botón ADMIN abajo-izquierda (temporal).
class PantallaJardin extends StatefulWidget {
  const PantallaJardin({super.key});

  @override
  State<PantallaJardin> createState() => _PantallaJardinState();
}

class _PantallaJardinState extends State<PantallaJardin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _balanceo;
  bool _panelAbierto = false;

  /// Activa mientras la animación de recolección está en marcha.
  /// Mientras esté true, se muestra el overlay con la flor volando hacia
  /// el ramo y se oculta el botón "Recoger flor" para evitar dobles taps.
  bool _animandoRecoleccion = false;

  /// Activa mientras la animación de riego (gotas cayendo) está en marcha.
  /// Bloquea el botón "Regar" para que no se pueda activar dos veces.
  bool _animandoRiego = false;

  @override
  void initState() {
    super.initState();
    _balanceo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    // Tutorial de bienvenida — solo se muestra la primera vez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TutorialJardin.mostrarSiHaceFalta(context);
    });
  }

  @override
  void dispose() {
    _balanceo.dispose();
    super.dispose();
  }

  void _togglePanel() => setState(() => _panelAbierto = !_panelAbierto);

  /// Inicia la animación de recolección. Se llama al pulsar el botón
  /// "Recoger flor" cuando el jazmín está completamente desarrollado.
  void _iniciarRecoleccion() {
    if (_animandoRecoleccion) return;
    // Abrimos automáticamente el panel para que la flor llegue al ramo
    // que será visible cuando termine la animación.
    setState(() {
      _animandoRecoleccion = true;
      _panelAbierto = true;
    });
  }

  /// Se llama al finalizar la animación. Actualiza el estado del jardín
  /// (suma la flor al ramo y reinicia la racha) y oculta el overlay.
  Future<void> _terminarRecoleccion() async {
    await EstadoJardin.recolectarFlor();
    if (mounted) setState(() => _animandoRecoleccion = false);
  }

  /// Inicia la animación de riego. Se llama al pulsar el botón "Regar".
  /// **Siempre se puede tocar** (sin importar si ya regó hoy o no):
  /// cada toque reduce 10 % de marchitez, o REPLANTA si la flor murió.
  void _iniciarRiego() {
    if (_animandoRiego) return;
    setState(() => _animandoRiego = true);
  }

  /// Al terminar la animación de gotas, aplica el riego al estado y
  /// oculta el overlay. Si el riego hizo crecer la racha al máximo,
  /// el botón "Recoger" aparecerá automáticamente en su lugar.
  Future<void> _terminarRiego() async {
    await EstadoJardin.regarPlanta();
    if (mounted) setState(() => _animandoRiego = false);
  }

  /// Decide qué widget mostrar en el espacio inferior CENTRAL:
  ///  · "Recoger flor" cuando el jazmín está al máximo
  ///  · El mensaje romántico el resto del tiempo
  ///
  /// El botón "Regar" siempre está visible aparte (esquina inferior-dcha),
  /// así que ya no compite con esta sección.
  Widget _construirBotonInferior() {
    if (EstadoJardin.listaParaCosechar && !_animandoRecoleccion) {
      return _BotonRecoger(onTap: _iniciarRecoleccion);
    }
    return const _MensajeInferior();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<int>(
        valueListenable: HoraEfectiva.hora,
        builder: (_, horaActual, __) {
          final periodo = PeriodoDia.deHora(horaActual);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. FONDO real — imagen del jardín (día/atardecer/noche)
              //    con su filtro ambiente aplicado dentro del propio widget.
              const Positioned.fill(child: FondoJardinBotanico()),

              // 2. Luciérnagas — solo de noche, evitando la zona central.
              if (periodo.esNoche)
                const Positioned.fill(
                  child: LuciernagasAnimadas(densidad: 22),
                ),

              // 3. Vignette para que el ojo se centre en la maceta.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.38, 0.74, 1.0],
                  ),
                ),
              ),

              // 4. CONTENIDO — UI + maceta + jazmín, todos compartiendo
              //    el mismo `periodo`.
              SafeArea(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    EstadoJardin.diasRacha,
                    EstadoJardin.floresEnRamo,
                    EstadoJardin.marchitez,
                    EstadoJardin.regadaHoy,
                    _balanceo,
                  ]),
                  builder: (_, __) => LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = constraints.maxWidth;
                      final alto = constraints.maxHeight;

                      // Canvas de la escena (jazmín + maceta-imagen).
                      // Relación 1 : 2.3 — la maceta-imagen (1:1) ocupa
                      // la franja inferior y el jazmín crece hacia arriba.
                      // Tamaño intermedio: ni domina la mesa ni se pierde.
                      final escenaW = (ancho * 0.32).clamp(130.0, 210.0);
                      final escenaH = escenaW * 2.3;

                      return Stack(
                        children: [
                          // ────── TÍTULO (TOP-LEFT) ──────
                          const Positioned(
                              top: 8, left: 16, child: _Titulo()),

                          // ────── BADGE ESTADO (TOP-RIGHT) ──────
                          const Positioned(
                            top: 8,
                            right: 16,
                            child: _BadgeEstadoJazmin(),
                          ),

                          // ────── ESCENA: JAZMÍN + MACETA-IMAGEN ──────
                          // Bottom alineado con la mesa de la foto.
                          // 0.62 deja la maceta apoyada sobre el tablero,
                          // con su base ligeramente por delante del borde.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: alto * 0.62 - escenaH,
                            height: escenaH,
                            child: Center(
                              child: SizedBox(
                                width: escenaW,
                                height: escenaH,
                                child: RepaintBoundary(
                                  child: Stack(
                                    children: [
                                      // Maceta foto con filtro de ambiente.
                                      Positioned.fill(
                                        child: MacetaImagen(periodo: periodo),
                                      ),
                                      // Jazmín procedural por encima,
                                      // tinte de luz coincidente.
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: JazminPainter(
                                            progreso: EstadoJardin
                                                .progresoFlorActual,
                                            marchitez: EstadoJardin
                                                .marchitez.value,
                                            tiempoAnimacion:
                                                _balanceo.value * 6.2832,
                                            periodo: periodo,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ────── PESTAÑA + PANEL DESLIZABLE ──────
                          Positioned(
                            right: 0,
                            top: alto * 0.30,
                            bottom: alto * 0.20,
                            child: _PanelLateralDeslizable(
                              panelAbierto: _panelAbierto,
                              onTogglePanel: _togglePanel,
                              tiempoAnimacion: _balanceo.value * 6.2832,
                            ),
                          ),

                          // ────── BOTÓN INFERIOR  /  MENSAJE ──────
                          // Prioridades:
                          //  1. "Recoger" si el jazmín está al máximo y
                          //     el ramo no está lleno (y no animando).
                          //  2. "Regar" si aún no se regó hoy (y no
                          //     animando un riego en curso).
                          //  3. Mensaje romántico habitual.
                          Positioned(
                            bottom: 8,
                            left: 16,
                            right: 16,
                            child: _construirBotonInferior(),
                          ),

                          // ────── BOTÓN REGAR (siempre visible) ──────
                          // FAB pequeño con icono de gota. Se puede pulsar
                          // las veces que quiera — cada tap quita 10 % de
                          // marchitez. Se oculta solo durante las animaciones.
                          if (!_animandoRiego && !_animandoRecoleccion)
                            Positioned(
                              right: 16,
                              bottom: 70,
                              child: _BotonRegar(onTap: _iniciarRiego),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // 5. OVERLAY: animación de recolección — vuela sobre toda
              //    la UI cuando la usuaria pulsa "Recoger flor".
              if (_animandoRecoleccion)
                Positioned.fill(
                  child: AnimacionRecoleccion(
                    onCompleta: _terminarRecoleccion,
                  ),
                ),

              // 6. OVERLAY: animación de riego — gotas cayendo sobre la
              //    planta cuando la usuaria pulsa "Regar".
              if (_animandoRiego)
                Positioned.fill(
                  child: AnimacionRiego(onCompleta: _terminarRiego),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Título "Mi Jardín" con backdrop dorado-oscuro para garantizar legibilidad.
class _Titulo extends StatelessWidget {
  const _Titulo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 18, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.granateNoche.withValues(alpha: 0.82),
            AppColors.granateProfundo.withValues(alpha: 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mi Jardín',
            style: GoogleFonts.greatVibes(
              fontSize: 44,
              color: AppColors.oroClaro,
              fontWeight: FontWeight.w400,
              height: 0.95,
              shadows: [
                Shadow(
                  color: AppColors.granateNoche,
                  blurRadius: 14,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
          ),
          Container(
            width: 90,
            height: 1.2,
            margin: const EdgeInsets.only(top: 2, bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.oro,
                  AppColors.oro.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Text(
            'Para mi amor',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 13,
              color: AppColors.oroClaro.withValues(alpha: 0.92),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.4,
              shadows: [
                Shadow(
                  color: AppColors.granateNoche.withValues(alpha: 0.7),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge con día y estado (top-right).
class _BadgeEstadoJazmin extends StatelessWidget {
  const _BadgeEstadoJazmin();

  @override
  Widget build(BuildContext context) {
    final dias = EstadoJardin.diasRacha.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.granate.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.oro.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Día $dias / ${EstadoJardin.diasParaFlorecer}',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.oroClaro,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            EstadoJardin.estadoJazmin(),
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.oroClaro.withValues(alpha: 0.82),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña-flecha en el borde derecho + panel detallado deslizable.
/// El panel detallado incluye el RAMO visual arriba (jarrón con los
/// jazmines recolectados) y las 3 secciones de stats debajo.
class _PanelLateralDeslizable extends StatelessWidget {
  final bool panelAbierto;
  final VoidCallback onTogglePanel;
  final double tiempoAnimacion;

  const _PanelLateralDeslizable({
    required this.panelAbierto,
    required this.onTogglePanel,
    required this.tiempoAnimacion,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Panel detallado — se desliza desde la derecha.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            right: panelAbierto ? 22 : -150,
            width: 138,
            child: _PanelDetalle(tiempoAnimacion: tiempoAnimacion),
          ),
          // Pestaña-flecha siempre visible en el borde derecho.
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _PestanaToggle(
                abierto: panelAbierto,
                onTap: onTogglePanel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña-flecha en el borde derecho que abre/cierra el panel.
class _PestanaToggle extends StatelessWidget {
  final bool abierto;
  final VoidCallback onTap;

  const _PestanaToggle({required this.abierto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.granate.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          border: Border.all(
            color: AppColors.oro.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(-1, 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 280),
            turns: abierto ? 0.0 : 0.5,
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.oroClaro,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel detallado: jarrón con jazmines recolectados ARRIBA, y las
/// 3 secciones de stats (racha / ramo / cumple) ABAJO.
class _PanelDetalle extends StatelessWidget {
  final double tiempoAnimacion;

  const _PanelDetalle({required this.tiempoAnimacion});

  @override
  Widget build(BuildContext context) {
    final dias = EstadoJardin.diasRacha.value;
    final flores = EstadoJardin.floresEnRamo.value;
    final hastaCumple = EstadoJardin.diasParaCumpleanos();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.granateProfundo.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.oro.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ━━━ RAMO físico (jarrón + jazmines) — ocupa la parte
          //     superior del panel con un alto fijo (140 px). Suficiente
          //     para que el jarrón y el cluster de flores se vean bien
          //     sin que queden tallos kilométricos.
          Spacer(),
          Text(
            'JAZMINES RECOLECTADOS',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.oroClaro.withValues(alpha: 0.75),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          Spacer(),
          SizedBox(
            height: 140,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: RamoPainter(
                  flores: flores,
                  floresTotal: EstadoJardin.floresParaRamo,
                  tiempoAnimacion: tiempoAnimacion,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _DivisorPanel(),
          // ━━━ Stats (texto bajado) — tercio inferior del panel.
          _SeccionPanel(
            icono: const IconoLlama(size: 14),
            titulo: 'RACHA',
            valor: '$dias ${dias == 1 ? "día" : "días"}',
          ),
          const _DivisorPanel(),
          _SeccionPanel(
            icono: const IconoJazminMini(size: 14),
            titulo: 'RAMO',
            valor: '$flores de ${EstadoJardin.floresParaRamo}',
            extra: _FlorIcons(
              completas: flores,
              total: EstadoJardin.floresParaRamo,
            ),
          ),
          const _DivisorPanel(),
          _SeccionPanel(
            icono: const IconoCorazonOrnamentado(size: 14),
            titulo: 'CUMPLEAÑOS',
            valor: hastaCumple > 0
                ? 'En $hastaCumple ${hastaCumple == 1 ? "día" : "días"}'
                : hastaCumple == 0
                    ? '¡Es hoy!'
                    : 'Pasó',
          ),
          Spacer()
        ],
      ),
    );
  }
}

class _SeccionPanel extends StatelessWidget {
  final Widget icono;
  final String titulo;
  final String valor;
  final Widget? extra;

  const _SeccionPanel({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icono,
            const SizedBox(width: 6),
            Text(
              titulo,
              style: GoogleFonts.cormorantGaramond(
                color: AppColors.oroClaro.withValues(alpha: 0.65),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.oroClaro,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (extra != null) ...[
          const SizedBox(height: 5),
          extra!,
        ],
      ],
    );
  }
}

class _DivisorPanel extends StatelessWidget {
  const _DivisorPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.oro.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _FlorIcons extends StatelessWidget {
  final int completas;
  final int total;

  const _FlorIcons({required this.completas, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: i < completas
                ? const IconoJazminMini(size: 11)
                : Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.oroClaro.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _MensajeInferior extends StatelessWidget {
  const _MensajeInferior();

  @override
  Widget build(BuildContext context) {
    final dias = EstadoJardin.diasRacha.value;
    final maxDias = EstadoJardin.diasParaFlorecer;
    final m = EstadoJardin.marchitez.value;

    final regada = EstadoJardin.regadaHoy.value;
    final muerta = m >= 0.999;
    String mensaje;
    Color colorTexto = AppColors.oroClaro;
    if (muerta) {
      // ━━━ Estado MUERTA — mensaje destacado en rojo apagado ━━━
      mensaje = 'Tu jazmín se marchitó 💔';
      colorTexto = const Color(0xFFE89090);
    } else if (m > 0.55) {
      mensaje = 'Tu jazmín te está extrañando';
    } else if (m > 0) {
      mensaje = 'Le falta un poco de agua amor';
    } else if (dias == 0) {
      mensaje = 'Plantemos juntos un nuevo jazmín';
    } else if (regada) {
      // Después de regar: mensaje cariñoso confirmando el cuidado.
      if (dias < 7) {
        mensaje = 'Regado con amor · día $dias de $maxDias';
      } else if (dias < 14) {
        mensaje = '$dias días seguidos. Está por florecer';
      } else {
        mensaje = '¡Tu jazmín floreció!';
      }
    } else {
      mensaje = 'Tu jazmín espera su riego diario';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              AppColors.granateNoche.withValues(alpha: muerta ? 0.80 : 0.65),
              Colors.transparent,
            ],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            mensaje,
            key: ValueKey(mensaje),
            textAlign: TextAlign.center,
            style: GoogleFonts.greatVibes(
              fontSize: 28,
              color: colorTexto,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  color: AppColors.granateNoche,
                  blurRadius: 8,
                  offset: const Offset(1, 2),
                ),
                Shadow(
                  color: AppColors.granateNoche.withValues(alpha: 0.6),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón "Recoger flor" — aparece en el lugar del mensaje inferior
/// cuando el jazmín está completamente desarrollado. Pulsa suavemente
/// con un halo dorado para invitar al tap. Al pulsarlo, dispara
/// [onTap] que en `PantallaJardin` inicia la animación de recolección.
class _BotonRecoger extends StatefulWidget {
  final VoidCallback onTap;

  const _BotonRecoger({required this.onTap});

  @override
  State<_BotonRecoger> createState() => _BotonRecogerState();
}

class _BotonRecogerState extends State<_BotonRecoger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulso,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_pulso.value);
          final scale = 1.0 + t * 0.04;
          final glow = 6.0 + t * 14.0;
          return Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(28),
                splashColor: AppColors.oroClaro.withValues(alpha: 0.35),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE8C868),
                        const Color(0xFFD4A848),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.granateNoche.withValues(alpha: 0.75),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD166).withValues(alpha: 0.55),
                        blurRadius: glow,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_florist_rounded,
                        color: AppColors.granateNoche,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Recoger flor',
                        style: GoogleFonts.greatVibes(
                          color: AppColors.granateNoche,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          height: 0.95,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Botón "Regar" — un FAB pequeño con icono de gota de agua. Se puede
/// tocar **cuantas veces se quiera**: cada toque reduce 10 % de la
/// marchitez actual. Pulsa suavemente con un halo azul-agua para
/// invitar al tap.
class _BotonRegar extends StatefulWidget {
  final VoidCallback onTap;

  const _BotonRegar({required this.onTap});

  @override
  State<_BotonRegar> createState() => _BotonRegarState();
}

class _BotonRegarState extends State<_BotonRegar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulso,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_pulso.value);
        final scale = 1.0 + t * 0.05;
        final glow = 6.0 + t * 10.0;
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onTap,
              customBorder: const CircleBorder(),
              splashColor: const Color(0xFF8FCFEC).withValues(alpha: 0.5),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFAEE0F2), // celeste muy claro arriba
                      Color(0xFF4D88B0), // azul profundo abajo
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.granateNoche.withValues(alpha: 0.75),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8FCFEC).withValues(alpha: 0.55),
                      blurRadius: glow,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.granateNoche,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
