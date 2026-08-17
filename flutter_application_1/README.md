# MapX Validator

Offline-first Flutter app for MapX RPU field validators: search parcels, queue
them for a site visit, navigate to them on foot/by road, capture GPS
coordinates and photos, and submit validations — with local caching so work
saved in the field isn't lost without a connection.

## Stack

- **State**: Riverpod
- **Local storage**: Drift (SQLite) for parcels/validations/sync queue,
  `flutter_secure_storage` for auth tokens and cached navigation state
- **Maps**: `flutter_map` + OpenStreetMap tiles
- **Routing**: Valhalla (public demo instance by default — see below)
- **Networking**: Dio

## Configuration

- API base URL and endpoints: `lib/core/constants/app_constants.dart`
  (`ApiConstants`)
- Routing engine: `RoutingConstants.valhallaBaseUrl` in the same file. Point
  this at a self-hosted or offline Valhalla instance for production/offline
  use — nothing else in the routing layer (`lib/features/navigation/`) needs
  to change.

## Running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift/Riverpod codegen
flutter run
```

## Regenerating the app icon

The launcher icon is generated from `assets/images/mapx_icon.png` (a
square, alpha-free version of the MapX logo) via `flutter_launcher_icons`.
After changing the source image, regenerate with:

```bash
dart run flutter_launcher_icons
```
