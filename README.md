# ZyN

> Un regalo para mi vida 💌

Aplicación Flutter de regalo: una galería romántica vintage con reproductor
de música, cuenta regresiva al "día del reencuentro" y notificaciones cariñosas.

## Características

- 📸 **Galería personal** — añade fotos y videos desde la cámara o la galería del
  dispositivo. Todo se persiste en el dispositivo (`shared_preferences`).
- 🎞️ **Filtro sepia vintage** y miniaturas con marcos dorados.
- 🎶 **Reproductor de música** con vista de tocadiscos (vinilo animado, brazo,
  visualizador de audio) y modos shuffle/repeat.
- ⏳ **Cuenta regresiva** al día del encuentro, con notificaciones automáticas a
  1 semana y 1 día antes.
- ⚙️ **Personalización** — escala global de la UI y volumen persistido entre
  sesiones.

## Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada y tema
├── core/
│   ├── estado_global.dart     # Estado persistente (SharedPreferences)
│   ├── notificaciones.dart    # Wrapper sobre flutter_local_notifications
│   └── theme.dart             # Paleta y filtro sepia compartido
├── screens/
│   ├── splash_screen.dart     # Carga inicial + animación del corazón
│   ├── galeria_screen.dart    # Pantalla principal
│   └── detalle_album_screen.dart  # Vista a pantalla completa
└── widgets/
    ├── estado_vacio.dart      # Mensaje cuando la galería está vacía
    ├── reproductor_vintage.dart   # Mini-radio del bottom bar
    ├── reproductor_vinilo.dart    # Vista tocadiscos en pantalla completa
    ├── sheet_configuracion.dart   # Modal de configuración
    ├── tarjeta_recuerdo.dart      # Card animada de la galería
    └── widgets_video.dart         # Miniatura + reproductor de video
```

## Cómo correr

```bash
flutter pub get
flutter run
```

Para regenerar los íconos de launcher tras cambiar `assets/images/Logo.jpg`:

```bash
dart run flutter_launcher_icons
```

## Tests

```bash
flutter test
```
