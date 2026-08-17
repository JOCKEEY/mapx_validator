import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../parcel/domain/parcel_models.dart';
import '../../domain/travel_mode.dart';
import '../providers/navigation_controller.dart';

/// Turn-by-turn-style navigation from the validator's current GPS location
/// to a selected MapX parcel, routed over the real road/path network.
class NavigationScreen extends ConsumerStatefulWidget {
  final LandParcel parcel;

  const NavigationScreen({super.key, required this.parcel});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final MapController _mapController = MapController();
  bool _hasFitBounds = false;

  @override
  void initState() {
    super.initState();
    ref.read(navigationControllerProvider.notifier).initialize(widget.parcel);
  }

  /// Fit the map so the current location and target parcel are both
  /// visible. Runs once when enough data is available; the map controls
  /// offer a manual re-fit afterwards so live tracking doesn't keep
  /// yanking the camera around.
  void _fitBoundsOnce(NavigationState state) {
    if (_hasFitBounds) return;

    final points = <LatLng>[
      if (state.currentLocation != null) state.currentLocation!,
      if (state.accessPoint != null) state.accessPoint!.point,
      for (final ring in widget.parcel.polygonRings) ...ring,
    ];
    if (points.length < 2) return;

    _hasFitBounds = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(40, 140, 40, 200),
        ),
      );
    });
  }

  void _refit() {
    _hasFitBounds = false;
    _fitBoundsOnce(ref.read(navigationControllerProvider));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(navigationControllerProvider);
    _fitBoundsOnce(state);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Navigate: ${widget.parcel.identifierLabel}')),
      body: Stack(
        children: [
          Positioned.fill(
            child: _NavigationMap(
              mapController: _mapController,
              parcel: widget.parcel,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _RouteInfoCard(parcel: widget.parcel),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: _MapControlButton(
                icon: Icons.center_focus_strong,
                onTap: _refit,
              ),
            ),
          ),
          if (state.route == null &&
              state.status == NavigationStatus.loadingRoute)
            const _CenteredMessage(
              icon: null,
              message: 'Getting your location and calculating a route…',
              showSpinner: true,
            ),
          if (state.route == null && state.status == NavigationStatus.error)
            _CenteredMessage(
              icon: Icons.error_outline,
              message: state.errorMessage ?? 'Unable to calculate a route.',
              showSpinner: false,
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(top: false, child: _NavigationControls()),
          ),
        ],
      ),
    );
  }
}

/// The FlutterMap itself. Isolated in its own widget watching only the map
/// layer state (route/parcel/location/accuracy) so the app bar and other
/// chrome around it don't rebuild on every GPS tick.
class _NavigationMap extends ConsumerWidget {
  final MapController mapController;
  final LandParcel parcel;

  const _NavigationMap({required this.mapController, required this.parcel});

  static const _defaultCenter = LatLng(8.9483, 125.5406);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(
      navigationControllerProvider.select((s) => s.route),
    );
    final accessPoint = ref.watch(
      navigationControllerProvider.select((s) => s.accessPoint),
    );
    final currentLocation = ref.watch(
      navigationControllerProvider.select((s) => s.currentLocation),
    );
    final currentAccuracy = ref.watch(
      navigationControllerProvider.select((s) => s.currentAccuracy),
    );

    final polygonRings = parcel.polygonRings;
    final initialCenter =
        currentLocation ??
        accessPoint?.point ??
        (polygonRings.isNotEmpty && polygonRings.first.isNotEmpty
            ? polygonRings.first.first
            : _defaultCenter);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: initialCenter, initialZoom: 16),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mapx.validator',
        ),
        if (polygonRings.isNotEmpty)
          PolygonLayer(
            polygons: [
              for (final ring in polygonRings)
                Polygon(
                  points: ring,
                  color: AppTheme.successColor.withValues(alpha: 0.25),
                  borderColor: AppTheme.successColor,
                  borderStrokeWidth: 3,
                ),
            ],
          ),
        if (route != null && route.points.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                color: AppTheme.primaryColor,
                strokeWidth: 5,
              ),
            ],
          ),
        if (currentLocation != null && currentAccuracy != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: currentLocation,
                radius: currentAccuracy,
                useRadiusInMeter: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (currentLocation != null)
              Marker(
                point: currentLocation,
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            if (accessPoint != null)
              Marker(
                point: accessPoint.point,
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.errorColor,
                  size: 36,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Distance / ETA / GPS accuracy / travel mode / offline status card
class _RouteInfoCard extends ConsumerWidget {
  final LandParcel parcel;

  const _RouteInfoCard({required this.parcel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navigationControllerProvider);
    final route = state.route;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isOffline)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.usingCachedRoute
                          ? 'Offline — showing last known route'
                          : 'Offline — route may be outdated',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.social_distance,
                  label: 'Distance',
                  value: route?.formattedDistance ?? '--',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.timer_outlined,
                  label: 'ETA',
                  value: route?.formattedDuration ?? '--',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.gps_fixed,
                  label: 'GPS accuracy',
                  value: state.currentAccuracy != null
                      ? '±${state.currentAccuracy!.toStringAsFixed(0)} m'
                      : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TravelModeSelector(current: state.travelMode),
          if (state.accessPoint != null) ...[
            const SizedBox(height: 6),
            Text(
              'Target: ${state.accessPoint!.label}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
          if (state.status == NavigationStatus.recalculating) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text(
                  'Recalculating route…',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _TravelModeSelector extends ConsumerWidget {
  final TravelMode current;

  const _TravelModeSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<TravelMode>(
      segments: const [
        ButtonSegment(
          value: TravelMode.walking,
          icon: Icon(Icons.directions_walk, size: 16),
          label: Text('Walk'),
        ),
        ButtonSegment(
          value: TravelMode.driving,
          icon: Icon(Icons.directions_car, size: 16),
          label: Text('Drive'),
        ),
        ButtonSegment(
          value: TravelMode.bicycle,
          icon: Icon(Icons.directions_bike, size: 16),
          label: Text('Bike'),
        ),
      ],
      selected: {current},
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12),
      ),
      onSelectionChanged: (selection) {
        ref
            .read(navigationControllerProvider.notifier)
            .setTravelMode(selection.first);
      },
    );
  }
}

class _NavigationControls extends ConsumerWidget {
  const _NavigationControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(
      navigationControllerProvider.select((s) => s.isNavigating),
    );
    final status = ref.watch(
      navigationControllerProvider.select((s) => s.status),
    );
    final hasRoute = ref.watch(
      navigationControllerProvider.select((s) => s.route != null),
    );
    final isBusy =
        status == NavigationStatus.loadingRoute ||
        status == NavigationStatus.recalculating;
    final notifier = ref.read(navigationControllerProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : notifier.recalculateRoute,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Recalculate'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !hasRoute
                ? null
                : () {
                    if (isNavigating) {
                      notifier.stopNavigating();
                    } else {
                      notifier.startNavigating();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isNavigating
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: Icon(isNavigating ? Icons.stop : Icons.navigation, size: 18),
            label: Text(isNavigating ? 'Stop Navigation' : 'Start Navigation'),
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData? icon;
  final String message;
  final bool showSpinner;

  const _CenteredMessage({
    required this.icon,
    required this.message,
    required this.showSpinner,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner) const CircularProgressIndicator(),
                if (icon != null)
                  Icon(icon, color: AppTheme.errorColor, size: 32),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
