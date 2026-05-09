import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ZyN/core/estado_global.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EstadoGlobal', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('inicializar carga valores por defecto cuando no hay nada guardado',
        () async {
      // Reseteo del flag interno para tests independientes.
      await SharedPreferences.getInstance().then((p) => p.clear());
      EstadoGlobal.escalaApp.value = 1.0;
      EstadoGlobal.volumenMusica.value = 0.8;
      EstadoGlobal.recuerdos.value = const [];

      await EstadoGlobal.inicializar();

      expect(EstadoGlobal.escalaApp.value, 1.0);
      expect(EstadoGlobal.volumenMusica.value, 0.8);
      expect(EstadoGlobal.recuerdos.value, isEmpty);
    });

    test('agregarRecuerdo persiste y notifica', () async {
      await EstadoGlobal.inicializar();

      var notificaciones = 0;
      EstadoGlobal.recuerdos.addListener(() => notificaciones++);

      await EstadoGlobal.agregarRecuerdo(
        const Recuerdo(tipo: TipoMedio.fotoLocal, archivo: '/tmp/foto.jpg'),
      );

      expect(EstadoGlobal.recuerdos.value, hasLength(1));
      expect(EstadoGlobal.recuerdos.value.first.archivo, '/tmp/foto.jpg');
      expect(notificaciones, greaterThan(0));
    });
  });

  test('TipoMedio convierte ida y vuelta con sus claves', () {
    for (final t in TipoMedio.values) {
      expect(TipoMedioX.desdeClave(t.clave), t);
    }
    expect(TipoMedioX.desdeClave('inexistente'), isNull);
  });
}
