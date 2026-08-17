import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/location/location_service.dart';
import '../../../parcel/domain/parcel_models.dart';
import '../../data/navigation_cache_service.dart';
import '../../domain/navigation_models.dart';
import '../../domain/parcel_routing_service.dart';
import '../../domain/routing_service.dart';
import '../../domain/travel_mode.dart';

enum NavigationStatus { idle, loadingRoute, ready, recalculating, error }

/// Everything the navigation screen needs to render: the target parcel,
/// resolved access point, current position, active route, and status.
class NavigationState {
  final LandParcel? parcel;
  final ParcelAccessPoint? accessPoint;
  final LatLng? currentLocation;
  final double? currentAccuracy;
  final NavigationRoute? route;
  final TravelMode travelMode;
  final bool isNavigating;
  final NavigationStatus status;
  final String? errorMessage;
  final bool isOffline;
  final bool usingCachedRoute;

  const NavigationState({
    this.parcel,
    this.accessPoint,
    this.currentLocation,
    this.currentAccuracy,
    this.route,
    this.travelMode = TravelMode.walking,
    this.isNavigating = false,
    this.status = NavigationStatus.idle,
    this.errorMessage,
    this.isOffline = false,
    this.usingCachedRoute = false,
  });

  NavigationState copyWith({
    LandParcel? parcel,
    ParcelAccessPoint? accessPoint,
    LatLng? currentLocation,
    double? currentAccuracy,
    NavigationRoute? route,
    bool clearRoute = false,
    TravelMode? travelMode,
    bool? isNavigating,
    NavigationStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? isOffline,
    bool? usingCachedRoute,
  }) {
    return NavigationState(
      parcel: parcel ?? this.parcel,
      accessPoint: accessPoint ?? this.accessPoint,
      currentLocation: currentLocation ?? this.currentLocation,
      currentAccuracy: currentAccuracy ?? this.currentAccuracy,
      route: clearRoute ? null : (route ?? this.route),
      travelMode: travelMode ?? this.travelMode,
      isNavigating: isNavigating ?? this.isNavigating,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOffline: isOffline ?? this.isOffline,
      usingCachedRoute: usingCachedRoute ?? this.usingCachedRoute,
    );
  }
}

/// Orchestrates parcel-to-validator navigation: resolves the parcel's
/// access point, calculates the route, tracks GPS while navigating, and
/// recalculates on deviation. Deliberately holds no reference to widgets
/// or BuildContext — routing/location concerns stay independent of the UI.
class NavigationController extends StateNotifier<NavigationState> {
  final RoutingService _routingService;
  final ParcelRoutingService _parcelRoutingService;
  final LocationService _locationService;
  final NavigationCacheService _cacheService;
  final bool Function() _isOnline;

  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastRecalculation;

  NavigationController({
    required RoutingService routingService,
    required ParcelRoutingService parcelRoutingService,
    required LocationService locationService,
    required NavigationCacheService cacheService,
    required bool Function() isOnline,
  }) : _routingService = routingService,
       _parcelRoutingService = parcelRoutingService,
       _locationService = locationService,
       _cacheService = cacheService,
       _isOnline = isOnline,
       super(const NavigationState());

  /// Load the parcel, get an initial GPS fix, resolve its access point,
  /// and calculate the first route. Call once when the navigation screen
  /// opens; call [startNavigating] separately to begin live tracking.
  Future<void> initialize(LandParcel parcel) async {
    state = state.copyWith(
      parcel: parcel,
      status: NavigationStatus.loadingRoute,
      clearError: true,
    );
    await _cacheService.saveSelectedParcel(parcel);

    // Show cached state immediately so there's something on screen while
    // the live fix/route calculation is still in flight.
    final cachedRoute = await _cacheService.getLastRoute();
    final cachedLocation = await _cacheService.getLastLocation();
    if (cachedRoute != null || cachedLocation != null) {
      state = state.copyWith(
        currentLocation: cachedLocation,
        route: cachedRoute,
        usingCachedRoute: cachedRoute != null,
      );
    }

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to obtain current location');
      }
      final current = LatLng(position.latitude, position.longitude);
      state = state.copyWith(
        currentLocation: current,
        currentAccuracy: position.accuracy,
      );
      await _cacheService.saveLastLocation(current);

      await _calculateRoute(current);
    } catch (e) {
      _handleRouteFailure(e);
    }
  }

  Future<void> _calculateRoute(LatLng currentLocation) async {
    final parcel = state.parcel;
    if (parcel == null) return;

    try {
      final accessPoint = await _parcelRoutingService.resolveAccessPoint(
        parcel,
      );
      final route = await _routingService.calculateRoute(
        origin: currentLocation,
        destination: accessPoint.point,
        travelMode: state.travelMode,
      );

      state = state.copyWith(
        accessPoint: accessPoint,
        route: route,
        status: NavigationStatus.ready,
        isOffline: false,
        usingCachedRoute: false,
        clearError: true,
      );
      await _cacheService.saveLastRoute(route);
    } catch (e) {
      _handleRouteFailure(e);
    }
  }

  void _handleRouteFailure(Object error) {
    final offline = !_isOnline();
    if (offline && state.route != null) {
      // No connection, but we already have a route (fresh or cached) —
      // keep showing it rather than replacing the map with an error.
      state = state.copyWith(
        status: NavigationStatus.ready,
        isOffline: true,
        usingCachedRoute: true,
      );
      return;
    }

    state = state.copyWith(
      status: NavigationStatus.error,
      errorMessage: _messageOf(error),
      isOffline: offline,
    );
  }

  /// Begin live GPS tracking: the location marker updates continuously and
  /// the route recalculates automatically if the validator strays from it.
  Future<void> startNavigating() async {
    if (state.isNavigating) return;
    state = state.copyWith(isNavigating: true);

    await _positionSubscription?.cancel();
    _positionSubscription = _locationService
        .getLocationUpdates(
          distanceFilter: RoutingConstants.navigationDistanceFilterMeters,
        )
        .listen(_onPositionUpdate);
  }

  void stopNavigating() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (mounted) state = state.copyWith(isNavigating: false);
  }

  Future<void> _onPositionUpdate(Position position) async {
    final current = LatLng(position.latitude, position.longitude);
    state = state.copyWith(
      currentLocation: current,
      currentAccuracy: position.accuracy,
    );
    await _cacheService.saveLastLocation(current);

    if (_hasDeviatedFromRoute(current) && _canRecalculateNow()) {
      await recalculateRoute();
    }
  }

  /// Nearest-vertex distance from [current] to the active route. Valhalla
  /// emits closely-spaced shape points, so this is a good approximation of
  /// true point-to-polyline distance without needing segment projection.
  bool _hasDeviatedFromRoute(LatLng current) {
    final route = state.route;
    if (route == null || route.points.isEmpty) return false;

    const distanceCalculator = Distance();
    var nearest = double.infinity;
    for (final point in route.points) {
      final d = distanceCalculator.as(LengthUnit.Meter, current, point);
      if (d < nearest) nearest = d;
    }
    return nearest > RoutingConstants.routeDeviationThresholdMeters;
  }

  bool _canRecalculateNow() {
    final last = _lastRecalculation;
    if (last == null) return true;
    return DateTime.now().difference(last) >=
        RoutingConstants.minRecalculationInterval;
  }

  /// Force a route recalculation from the current location right now
  Future<void> recalculateRoute() async {
    final current = state.currentLocation;
    if (current == null) return;

    _lastRecalculation = DateTime.now();
    state = state.copyWith(status: NavigationStatus.recalculating);
    await _calculateRoute(current);
  }

  void setTravelMode(TravelMode mode) {
    if (mode == state.travelMode) return;
    state = state.copyWith(travelMode: mode);
    recalculateRoute();
  }

  /// Strips the `Exception: ` prefix Dart adds to `Exception(message).toString()`
  String _messageOf(Object error) {
    if (error is Failure) return error.message;
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final navigationControllerProvider =
    StateNotifierProvider.autoDispose<NavigationController, NavigationState>((
      ref,
    ) {
      return NavigationController(
        routingService: ref.watch(routingServiceProvider),
        parcelRoutingService: ref.watch(parcelRoutingServiceProvider),
        locationService: ref.watch(locationServiceProvider),
        cacheService: ref.watch(navigationCacheServiceProvider),
        isOnline: () => ref.read(isOnlineProvider),
      );
    });
