import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de medio que la galería sabe mostrar.
enum TipoMedio { fotoAsset, fotoLocal, videoAsset, videoLocal }

extension TipoMedioX on TipoMedio {
  String get clave => switch (this) {
        TipoMedio.fotoAsset => 'foto',
        TipoMedio.fotoLocal => 'foto_local',
        TipoMedio.videoAsset => 'video',
        TipoMedio.videoLocal => 'video_local',
      };

  static TipoMedio? desdeClave(String? clave) => switch (clave) {
        'foto' => TipoMedio.fotoAsset,
        'foto_local' => TipoMedio.fotoLocal,
        'video' => TipoMedio.videoAsset,
        'video_local' => TipoMedio.videoLocal,
        _ => null,
      };

  bool get esVideo => this == TipoMedio.videoAsset || this == TipoMedio.videoLocal;
  bool get esLocal => this == TipoMedio.fotoLocal || this == TipoMedio.videoLocal;
}

/// Un recuerdo (foto o video) almacenado en la galería.
@immutable
class Recuerdo {
  final TipoMedio tipo;
  final String archivo;

  const Recuerdo({required this.tipo, required this.archivo});

  Map<String, String> toMapLegacy() => {'tipo': tipo.clave, 'archivo': archivo};

  Map<String, dynamic> toJson() => {'tipo': tipo.clave, 'archivo': archivo};

  static Recuerdo? desdeJson(Map<String, dynamic> json) {
    final tipo = TipoMedioX.desdeClave(json['tipo'] as String?);
    final archivo = json['archivo'] as String?;
    if (tipo == null || archivo == null) return null;
    return Recuerdo(tipo: tipo, archivo: archivo);
  }
}

/// Estado global persistente de la aplicación.
///
/// Mantiene el factor de escala de la UI, el volumen de música y la lista
/// de recuerdos del usuario en `SharedPreferences`. Los listeners exponen
/// `ValueNotifier` para que cada widget se reconstruya solo cuando sea
/// estrictamente necesario.
class EstadoGlobal {
  EstadoGlobal._();

  static const _kEscala = 'escala_app_zyn';
  static const _kVolumen = 'volumen_musica_zyn';
  static const _kRecuerdos = 'recuerdos_zyn_v1';
  static const _kFechaReencuentro = 'fecha_reencuentro';

  static final ValueNotifier<double> escalaApp = ValueNotifier<double>(1.0);
  static final ValueNotifier<double> volumenMusica = ValueNotifier<double>(0.8);
  static final ValueNotifier<List<Recuerdo>> recuerdos =
      ValueNotifier<List<Recuerdo>>(const []);

  static SharedPreferences? _prefs;
  static bool _inicializado = false;

  /// Carga todo el estado persistido. Idempotente: llamarla varias veces no hace nada.
  static Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    _prefs = await SharedPreferences.getInstance();
    escalaApp.value = _prefs!.getDouble(_kEscala) ?? 1.0;
    volumenMusica.value = _prefs!.getDouble(_kVolumen) ?? 0.8;
    recuerdos.value = _leerRecuerdos();
  }

  static List<Recuerdo> _leerRecuerdos() {
    final raw = _prefs?.getString(_kRecuerdos);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista
          .whereType<Map<String, dynamic>>()
          .map(Recuerdo.desdeJson)
          .whereType<Recuerdo>()
          .toList(growable: false);
    } catch (e) {
      debugPrint('No pude leer los recuerdos guardados: $e');
      return const [];
    }
  }

  static Future<void> _guardarRecuerdos() async {
    final json = jsonEncode(recuerdos.value.map((r) => r.toJson()).toList());
    await _prefs?.setString(_kRecuerdos, json);
  }

  /// Inserta un recuerdo al inicio de la lista (los más nuevos primero).
  static Future<void> agregarRecuerdo(Recuerdo recuerdo) async {
    recuerdos.value = [recuerdo, ...recuerdos.value];
    await _guardarRecuerdos();
  }

  static Future<void> agregarRecuerdos(Iterable<Recuerdo> nuevos) async {
    if (nuevos.isEmpty) return;
    recuerdos.value = [...nuevos, ...recuerdos.value];
    await _guardarRecuerdos();
  }

  static Future<void> eliminarRecuerdo(Recuerdo recuerdo) async {
    recuerdos.value = recuerdos.value
        .where((r) => !(r.archivo == recuerdo.archivo && r.tipo == recuerdo.tipo))
        .toList(growable: false);
    await _guardarRecuerdos();
  }

  static Future<void> cambiarEscala(double nuevaEscala) async {
    escalaApp.value = nuevaEscala;
    await _prefs?.setDouble(_kEscala, nuevaEscala);
  }

  static Future<void> cambiarVolumen(double nuevoVolumen) async {
    volumenMusica.value = nuevoVolumen;
    await _prefs?.setDouble(_kVolumen, nuevoVolumen);
  }

  static DateTime? get fechaReencuentro {
    final iso = _prefs?.getString(_kFechaReencuentro);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  static Future<void> guardarFechaReencuentro(DateTime fecha) async {
    await _prefs?.setString(_kFechaReencuentro, fecha.toIso8601String());
  }
}
