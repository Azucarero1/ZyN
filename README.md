# ZyN

> Un regalo para mi vida 💌

Aplicación Flutter de regalo: una galería romántica vintage con reproductor
de música, cuenta regresiva al día del reencuentro, una carta personalizada
y el **Jardín del Amor** — un jazmín que florece día a día con su cuidado.

---

## ✨ Características

### 🌸 Jardín del Amor
- Pantalla dedicada accesible deslizando desde la galería.
- Un jazmín procedural que crece a lo largo de 14 días — tallo, hojas
  palmadas y un racimo final de 12 pequeñas flores blancas.
- **Botón de riego** (gota azul) que reduce 10 % la marchitez por toque.
- Si la planta pasa varios días sin riego se va marchitando hasta morir
  — el siguiente riego la replanta automáticamente.
- Al alcanzar la flor plena, se **recoge** con una animación de pétalos
  hacia el ramo lateral.
- Objetivo a largo plazo: completar un **ramo de 5 jazmines** antes del
  día del cumpleaños.
- Tutorial de bienvenida la primera vez que se entra al jardín.

### 🌅 Ambiente que cambia con la hora
- Fondo botánico victoriano con tres versiones (día / atardecer / noche)
  que rotan automáticamente según la hora real del dispositivo.
- La maceta y el jazmín reciben filtros de luz coherentes con cada
  periodo (cálido al atardecer, frío y azulado de noche).
- De noche aparecen **luciérnagas parpadeando** alrededor de la planta.

### 📸 Galería personal
- Fotos y videos añadidos por el usuario desde la cámara o el carrete.
- Filtro sepia vintage y miniaturas con marcos dorados.
- Persistencia total en el dispositivo (`shared_preferences`).
- Vista a pantalla completa con transiciones suaves.

### 🎶 Reproductor de música vintage
- Vista de tocadiscos con vinilo animado, brazo y visualizador de audio.
- Mini-reproductor en la barra inferior siempre accesible.
- Modos shuffle y repeat.

### 💌 Carta romántica
- Pantalla dedicada con una carta escrita a mano, accesible desde un
  botón pulsante en la cabecera.
- Pétalos cayendo de fondo en bucle.

### 🔔 Notificaciones
- Recordatorio diario configurable (defecto 20:00) para regar la planta.
- Mensajes cariñosos al abrir la app.
- Avisos a 1 semana y 1 día antes del reencuentro.

### ⚙️ Personalización
- Escala global de la UI.
- Volumen del reproductor.
- Fecha del reencuentro.
- Hora del recordatorio diario de riego.

---

## 📦 Estructura del proyecto

```
lib/
├── main.dart                            # Punto de entrada y tema
├── core/
│   ├── estado_global.dart               # Estado persistente (galería, escala, volumen)
│   ├── estado_jardin.dart               # Racha, marchitez, ramo, tutorial
│   ├── notificaciones.dart              # Wrapper sobre flutter_local_notifications
│   └── theme.dart                       # Paleta granate/oro + filtro sepia
├── screens/
│   ├── splash_screen.dart               # Carga inicial + corazón latiendo
│   ├── galeria_screen.dart              # Pantalla principal con PageView
│   ├── jardin_screen.dart               # Jardín del Amor
│   ├── carta_screen.dart                # Carta romántica
│   └── detalle_album_screen.dart        # Vista a pantalla completa
└── widgets/
    ├── jardin_painter.dart              # Maceta + jazmín procedurales + iconos
    ├── maceta_imagen.dart               # Maceta foto con filtro de ambiente
    ├── fondo_jardin.dart                # Fondo botánico día/atardecer/noche
    ├── luciernagas_animadas.dart        # Luciérnagas parpadeantes nocturnas
    ├── animacion_riego.dart             # Gotas cayendo al regar
    ├── animacion_recoleccion.dart       # Flor volando al ramo
    ├── tutorial_jardin.dart             # Welcome dialog del jardín
    ├── petalos_animados.dart            # Pétalos cayendo de fondo
    ├── reproductor_vintage.dart         # Mini-radio del bottom bar
    ├── reproductor_vinilo.dart          # Vista tocadiscos a pantalla completa
    ├── sheet_configuracion.dart         # Modal de ajustes
    ├── tarjeta_recuerdo.dart            # Tarjeta animada de la galería
    ├── estado_vacio.dart                # Mensaje cuando la galería está vacía
    └── widgets_video.dart               # Miniatura + reproductor de video
```

---

## 🚀 Cómo ejecutar

Requiere Flutter (probado con 3.41) y un dispositivo Android conectado
o un emulador.

```bash
flutter pub get
flutter run
```

Para generar un APK release instalable:

```bash
flutter build apk --release
# Se genera en: build/app/outputs/flutter-apk/app-release.apk
```

Para regenerar los íconos del launcher tras cambiar
`assets/images/Logo.jpg`:

```bash
dart run flutter_launcher_icons
```

---

## 🧪 Tests

```bash
flutter test
```

---

## 📜 Versión

Actualmente en **1.1.0+2**.

| Versión | Cambios |
|---|---|
| 1.1.0 | Jardín del Amor, tutorial, recordatorios diarios, fondos día/noche |
| 1.0.0 | Galería, reproductor vintage, carta, cuenta regresiva |
