# Mercado

Marketplace para comprar y vender cerca de ti. Publica tu tienda, sube
productos y conecta con compradores por WhatsApp.

Descarga la app desde
[la página de descargas](https://fives56.github.io/mercado/) o desde
[GitHub Releases](https://github.com/Fives56/mercado/releases/latest).

## Funciones

- Catálogo con búsqueda, filtros y categorías.
- Tienda pública para cada vendedor.
- Registro e inicio de sesión con Supabase Auth.
- Panel de vendedor con CRUD de productos y tienda.
- Subida de imágenes a Supabase Storage.
- Contacto directo por WhatsApp.

## Stack

- Flutter 3.44.4 / Dart 3.12
- Riverpod
- go_router
- Supabase Auth, Postgres y Storage

## Desarrollo local

1. Instala Flutter 3.44.4.
2. Crea `supabase.json` en la raíz:

```json
{
  "SUPABASE_URL": "https://<proyecto>.supabase.co",
  "SUPABASE_ANON_KEY": "<publishable-key>"
}
```

3. Ejecuta la migración de `supabase/migrations/` en el SQL Editor de Supabase.
4. Instala dependencias y ejecuta:

```bash
flutter pub get
flutter run -d linux
```

> `supabase.json` está ignorado por Git. La publishable key puede ir en el
> cliente; la service role key nunca debe exponerse.

## Compilar

```bash
# Android
flutter build apk --release --dart-define-from-file=supabase.json

# Linux
flutter build linux --release --dart-define-from-file=supabase.json

# Windows (en Windows)
flutter build windows --release --dart-define-from-file=supabase.json
```

Para desarrollo:

```bash
flutter run -d linux
flutter run -d windows
flutter run -d <dispositivo-android>
```

## Releases

El workflow `.github/workflows/release.yml` compila Android, Linux y Windows y
publica los binarios en GitHub Releases al empujar un tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Los artefactos publicados son:

- `mercado-android.apk`
- `mercado-linux-x64.tar.gz`
- `mercado-windows-x64.zip`

La página de descargas vive en `docs/` y se publica con GitHub Pages.
No incluyas `supabase.json`, `build/` ni `.dart_tool/` en el repositorio.

## Firma de Android

El APK de release usa la firma de desarrollo para facilitar la instalación
directa. Para publicar en Google Play, configura un keystore propio en
`android/key.properties` y actualiza `android/app/build.gradle.kts`.
