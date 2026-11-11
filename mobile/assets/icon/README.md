# Ícono de la aplicación

Colocá aquí la imagen del ícono con el nombre exacto:

```
mobile/assets/icon/app_icon.png
```

Recomendaciones:

- PNG cuadrado (idealmente 1024 × 1024 px).
- Fondo opaco o transparente, según el diseño.
- Para el ícono adaptativo de Android se usa la misma imagen como
  `adaptive_icon_foreground` con fondo negro (`#000000`), por lo que
  conviene que el logo quede centrado y con margen interno.

Si usás otro nombre o formato (por ejemplo `.jpg`), actualizá
`image_path` en la sección `flutter_launcher_icons` de `pubspec.yaml`.

Generación de íconos:

```bash
flutter pub get
dart run flutter_launcher_icons
```
