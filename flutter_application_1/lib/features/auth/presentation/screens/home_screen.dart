import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../app/providers/app_providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../navigation/domain/navigation_models.dart';
import '../../../navigation/domain/travel_mode.dart';
import '../../../parcel/domain/parcel_models.dart';
import '../../../validation/domain/validation_models.dart';
import '../providers/auth_provider.dart';
import 'change_password_screen.dart';

/// Activity item model
class ActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });

  /// Formatted with both date and time, e.g. "Nov 15, 2025 • 6:35 PM"
  String get time => DateFormat('MMM d, y • h:mm a').format(timestamp);
}

/// Home/Dashboard screen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showAllActivity = false;

  @override
  Widget build(BuildContext context) {
    final queuedParcels = ref.watch(rpuQueueProvider).valueOrNull ?? [];
    final pendingCount = queuedParcels.length;
    final validationsByParcel = ref.watch(validationsByParcelProvider);
    final completedCount = queuedParcels.where((item) {
      final validation = validationsByParcel[item.id];
      return validation != null && validation.syncStatus == 'synced';
    }).length;
    final progress = pendingCount == 0 ? 0.0 : completedCount / pendingCount;

    // Real activity, derived from the RPU queue and local validations
    final validationRows = ref.watch(validationsProvider).valueOrNull ?? [];
    final activities = <ActivityItem>[
      for (final item in queuedParcels)
        ActivityItem(
          type: 'rpu_added',
          title: 'RPU Added',
          subtitle: '${item.owner} • PIN ${item.pin}',
          timestamp: item.addedAt,
          icon: Icons.add_circle,
          iconColor: AppTheme.infoColor,
        ),
      for (final validation in validationRows) ...[
        ActivityItem(
          type: 'validation_saved',
          title: 'Validation Saved Locally',
          subtitle: validation.tdNumber ?? validation.parcelId,
          timestamp: validation.createdAt,
          icon: Icons.save_outlined,
          iconColor: AppTheme.primaryColor,
        ),
        if (validation.syncedAt != null)
          ActivityItem(
            type: 'validation_sent',
            title: 'Validation Sent',
            subtitle: validation.tdNumber ?? validation.parcelId,
            timestamp: validation.syncedAt!,
            icon: Icons.cloud_done,
            iconColor: AppTheme.successColor,
          ),
      ],
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    const activityPageSize = 5;
    final recentActivities = _showAllActivity
        ? activities
        : activities.take(activityPageSize).toList();

    return Scaffold(
      appBar: const _MapXHeader(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Field Validator Header
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'My Field Validator',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              // Geo Tagging Progress Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GEO TAGGING PROGRESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$completedCount of $pendingCount Completed',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pending Validations Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PENDING VALIDATIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$pendingCount',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.map,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            _showMapView(context);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('VIEW MAP DETAILS'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.tune,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'No activity yet. Add an RPU or save a validation to see it here.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = recentActivities[index];
                    return _buildActivityItem(activity);
                  },
                ),
              if (activities.length > activityPageSize)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _showAllActivity = !_showAllActivity);
                    },
                    child: Text(_showAllActivity ? 'See Less' : 'See More'),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        onMapTap: () => _showMapView(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRPUDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build individual activity item
  Widget _buildActivityItem(ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(activity.icon, color: activity.iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),

          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Time
          Text(
            activity.time,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Show Add RPU screen
  void _showAddRPUDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _AddRPUPage(),
      ),
    );
  }

  /// Show Map View screen
  void _showMapView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _MapViewPage(),
      ),
    );
  }
}

/// Add RPU full-screen page — search MapX land records by PIN or TD Number
/// and queue selected parcels locally for later field validation.
class _AddRPUPage extends ConsumerStatefulWidget {
  const _AddRPUPage();

  @override
  ConsumerState<_AddRPUPage> createState() => _AddRPUPageState();
}

class _AddRPUPageState extends ConsumerState<_AddRPUPage> {
  late TextEditingController _searchController;
  List<LandParcel> _results = [];
  final Set<String> _selectedIds = {};
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search MapX land records by PIN or TD Number (comma-separated for
  /// multiple parcels); `searchBy` is auto-detected from the input.
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Enter a PIN or TD Number to search.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
      _selectedIds.clear();
    });

    final repository = ref.read(parcelRepositoryProvider);
    final result = await repository.searchLand(query);

    if (!mounted) return;

    result.match(
      (failure) {
        setState(() {
          _isSearching = false;
          _results = [];
          _errorMessage = failure.message;
        });
      },
      (parcels) {
        setState(() {
          _isSearching = false;
          _results = parcels;
        });
      },
    );
  }

  /// Persist the selected parcels locally so they can be picked up later
  /// during field validation.
  Future<void> _addSelectedToQueue() async {
    final repository = ref.read(parcelRepositoryProvider);
    final selected = _results
        .where((parcel) => _selectedIds.contains(parcel.id))
        .toList();

    for (final parcel in selected) {
      await repository.addToQueue(parcel);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${selected.length} RPU(s) to queue')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MapXHeader(),
      body: Column(
        children: [
          _PageTitleBar(
            title: 'Add RPU',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      const Text(
                        'Search by PIN or TD Number to add property units to your validation queue.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search field
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _performSearch(),
                        decoration: InputDecoration(
                          hintText: 'e.g. 049-05-0001-040-21, J-0101574',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: _isSearching ? null : _performSearch,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search results
                      Expanded(child: _buildResults()),
                    ],
                  ),
                ),

                // Floating selection bar
                if (selectedCount > 0)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$selectedCount Selected',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addSelectedToQueue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add to Queue',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        onHomeTap: () => Navigator.of(context).pop(),
        onMapTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const _MapViewPage(),
            ),
          );
        },
      ),
    );
  }

  /// Build the search results area: loading, error, empty, or list states
  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Search for a parcel by PIN or TD Number to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No matching parcels found.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildLandParcelCard(_results[index]),
    );
  }

  /// Build individual land parcel card
  Widget _buildLandParcelCard(LandParcel parcel) {
    final isSelected = _selectedIds.contains(parcel.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Identifier and land class
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.identifierLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PIN: ${parcel.pin}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                if (parcel.landClass != null && parcel.landClass!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      parcel.landClass!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Owner
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parcel.owner,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),

            // Location
            if (parcel.locationLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parcel.locationLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 10),

            // Select row
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(parcel.id);
                  } else {
                    _selectedIds.add(parcel.id);
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSelected ? 'Selected' : 'Select',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[400]!,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Map View full-screen page showing real queued parcels on the map
class _MapViewPage extends ConsumerStatefulWidget {
  const _MapViewPage();

  @override
  ConsumerState<_MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<_MapViewPage> {
  LandParcel? _selectedParcel;
  LatLng? _myLocation;
  final MapController _mapController = MapController();
  bool _hasAutoCentered = false;
  final Set<String> _sendingValidationIds = {};
  NavigationRoute? _routeToSelected;
  bool _isLoadingRoute = false;

  static const LatLng _defaultCenter = LatLng(8.9483, 125.5406);

  @override
  void initState() {
    super.initState();
    _fetchMyLocation();
  }

  /// Fetch the device's current location, falling back to a nearby point
  Future<void> _fetchMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission not granted');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (!mounted) return;
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Fall back to a sample point near the campus so the route line still shows
      if (!mounted) return;
      setState(() {
        _myLocation = const LatLng(8.9471, 125.5403);
      });
    }
  }

  /// Ray-casting point-in-polygon test
  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  void _handleMapTap(LatLng point, List<LandParcel> parcels) {
    LandParcel? tapped;
    for (final parcel in parcels) {
      for (final ring in parcel.polygonRings) {
        if (_pointInPolygon(point, ring)) {
          tapped = parcel;
          break;
        }
      }
      if (tapped != null) break;
    }
    setState(() {
      _selectedParcel = tapped;
      _routeToSelected = null;
    });
    if (tapped != null) _loadRouteToSelected(tapped);
  }

  /// Select a parcel and pan/zoom the map to its exact real-world location
  void _selectParcel(LandParcel parcel) {
    setState(() {
      _selectedParcel = parcel;
      _routeToSelected = null;
    });
    _loadRouteToSelected(parcel);
    final centroid = parcel.centroid;
    if (centroid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(centroid, 17.5);
      });
    }
  }

  /// Calculate a real walking route from the validator's current location
  /// to the selected parcel's resolved access point, over the actual
  /// road/path network — not a straight line — for the guide path shown
  /// on the map.
  Future<void> _loadRouteToSelected(LandParcel parcel) async {
    if (_myLocation == null) return;

    setState(() => _isLoadingRoute = true);
    try {
      final accessPoint = await ref
          .read(parcelRoutingServiceProvider)
          .resolveAccessPoint(parcel);
      final route = await ref
          .read(routingServiceProvider)
          .calculateRoute(
            origin: _myLocation!,
            destination: accessPoint.point,
            travelMode: TravelMode.walking,
          );

      if (!mounted || _selectedParcel?.id != parcel.id) return;
      setState(() => _routeToSelected = route);
    } catch (_) {
      // Leave _routeToSelected null; the map just won't show a guide line
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  /// Send a parcel's already-saved local validation straight away, without
  /// reopening the full form — used once a visit has already been captured
  /// and just needs to reach the server.
  Future<void> _sendExistingValidation(Validation validation) async {
    setState(() => _sendingValidationIds.add(validation.id));

    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(validationRepositoryProvider);
    final result = await repository.uploadValidation(
      validationId: validation.id,
    );

    if (!mounted) return;
    setState(() => _sendingValidationIds.remove(validation.id));

    result.match(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No connection — still saved locally, will send automatically when you\'re back online.',
            ),
          ),
        );
      },
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Validation sent')),
        );
      },
    );
  }

  /// Remove a parcel from the local validation queue, after confirming.
  /// Does not touch any validation already saved/sent for it — only clears
  /// it from the "to visit" list so the queue is ready for the next parcel.
  Future<void> _removeFromQueue(LandParcel parcel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from queue?'),
        content: Text(
          '${parcel.identifierLabel} will be removed from your validation queue. '
          'You can search and add it again later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(parcelRepositoryProvider)
        .removeFromQueue(parcel.id);

    if (!mounted) return;

    result.match(
      (failure) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to remove: ${failure.message}')),
        );
      },
      (_) {
        if (_selectedParcel?.id == parcel.id) {
          setState(() {
            _selectedParcel = null;
            _routeToSelected = null;
          });
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Removed from queue')),
        );
      },
    );
  }

  /// Straight-line distance from the user to the selected parcel, in meters
  double? get _distanceToSelected {
    final centroid = _selectedParcel?.centroid;
    if (_myLocation == null || centroid == null) return null;
    return Geolocator.distanceBetween(
      _myLocation!.latitude,
      _myLocation!.longitude,
      centroid.latitude,
      centroid.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parcels = ref.watch(rpuQueueParcelsProvider);

    // The first time queued parcels load, center the map on real data
    // instead of the generic fallback location.
    if (!_hasAutoCentered && parcels.isNotEmpty) {
      _hasAutoCentered = true;
      final centroid = parcels.first.centroid;
      if (centroid != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(centroid, 16);
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MapXHeader(),
      body: Column(
        children: [
          _PageTitleBar(
            title: 'Map View',
            onBack: () => Navigator.of(context).pop(),
            trailing: IconButton(
              icon: const Icon(Icons.history, color: AppTheme.textPrimaryColor),
              tooltip: 'Saved Validations',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const _SavedValidationsPage(),
                  ),
                );
              },
            ),
          ),
          // Map area
          _selectedParcel != null
              ? Expanded(child: _buildMapStack(parcels))
              : SizedBox(height: 220, child: _buildMapStack(parcels)),

          if (_selectedParcel != null)
            _buildSelectedUnitBar(context)
          else
            // Pending validations list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Validations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${parcels.length} Units',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: parcels.isEmpty
                          ? Center(
                              child: Text(
                                'No parcels queued yet. Add one from Add RPU.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: parcels.length,
                              itemBuilder: (context, index) {
                                return _buildParcelCard(
                                  context,
                                  parcels[index],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 1,
        onHomeTap: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Map with real parcel polygons, selection marker, and floating controls
  Widget _buildMapStack(List<LandParcel> parcels) {
    // Prefer the real calculated route's distance/time; fall back to a
    // straight-line estimate only for the label while the route is still
    // loading (no line is ever drawn for the straight-line estimate).
    final distance = _routeToSelected?.distanceMeters ?? _distanceToSelected;
    final minutes = _routeToSelected != null
        ? _routeToSelected!.duration.inMinutes.clamp(1, 999)
        : (distance == null ? null : (distance / 80).ceil().clamp(1, 999));
    final selectedCentroid = _selectedParcel?.centroid;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
              onTap: (tapPosition, point) => _handleMapTap(point, parcels),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mapx.validator',
              ),
              PolygonLayer(
                polygons: [
                  for (final parcel in parcels)
                    for (final ring in parcel.polygonRings)
                      Polygon(
                        points: ring,
                        color: _selectedParcel?.id == parcel.id
                            ? AppTheme.successColor.withValues(alpha: 0.45)
                            : AppTheme.successColor.withValues(alpha: 0.15),
                        borderColor: AppTheme.successColor,
                        borderStrokeWidth: _selectedParcel?.id == parcel.id
                            ? 3
                            : 2,
                      ),
                ],
              ),
              if (_routeToSelected != null && _routeToSelected!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeToSelected!.points,
                      color: AppTheme.primaryColor,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
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
                  if (_selectedParcel != null && selectedCentroid != null)
                    Marker(
                      point: selectedCentroid,
                      width: 160,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.errorColor,
                            size: 32,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              _selectedParcel!.locationLabel.isNotEmpty
                                  ? _selectedParcel!.locationLabel
                                  : _selectedParcel!.identifierLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedCentroid != null &&
                      _myLocation != null &&
                      distance != null)
                    Marker(
                      point: LatLng(
                        (_myLocation!.latitude + selectedCentroid.latitude) / 2,
                        (_myLocation!.longitude + selectedCentroid.longitude) /
                            2,
                      ),
                      width: 90,
                      height: 34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$minutes min\n${distance.round()}m',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Floating map controls
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _buildMapControlButton(Icons.layers),
              const SizedBox(height: 10),
              _buildMapControlButton(
                Icons.my_location,
                onTap: () {
                  if (_myLocation != null) {
                    _mapController.move(_myLocation!, 18);
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildMapControlButton(Icons.tune),
            ],
          ),
        ),

        // Route-calculation status
        if (_isLoadingRoute)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 6),
                  Text('Finding route…', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Circular floating icon button used for the map controls
  Widget _buildMapControlButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
    );
  }

  /// Bottom bar shown when a parcel is selected on the map
  Widget _buildSelectedUnitBar(BuildContext context) {
    final parcel = _selectedParcel!;
    final localValidation = ref.watch(validationsByParcelProvider)[parcel.id];
    final isSynced =
        localValidation != null && localValidation.syncStatus == 'synced';
    final needsSend = localValidation != null && !isSynced;
    final isSending =
        needsSend && _sendingValidationIds.contains(localValidation.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECTED UNIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  parcel.identifierLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (parcel.locationLabel.isNotEmpty)
                  Text(
                    parcel.locationLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.directions, color: AppTheme.primaryColor),
            tooltip: 'Navigate to parcel',
            onPressed: () {
              // Path must match RouteNames.mapNavigation in app_router.dart
              context.push('/map-navigation/${parcel.id}', extra: parcel);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[500]),
            tooltip: 'Remove from queue',
            onPressed: () => _removeFromQueue(parcel),
          ),
          if (isSynced)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
                const SizedBox(width: 6),
                Text(
                  'Validated',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : needsSend
                  ? () => _sendExistingValidation(localValidation)
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => _ValidationPage(parcel: parcel),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      needsSend ? 'Send Validation' : 'Validate',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  /// Build a pending validation parcel card
  /// Badge shown on a parcel card: unvisited, validated-but-unsent, or synced
  ({
    String label,
    IconData icon,
    double iconSize,
    Color color,
    Color background,
  })
  _statusBadgeFor(Validation? validation) {
    if (validation == null) {
      return (
        label: 'Pending',
        icon: Icons.circle,
        iconSize: 8,
        color: Colors.red[400]!,
        background: Colors.red[50]!,
      );
    }
    if (validation.syncStatus == 'synced') {
      return (
        label: 'Synced',
        icon: Icons.cloud_done,
        iconSize: 14,
        color: Colors.green[700]!,
        background: Colors.green[50]!,
      );
    }
    return (
      label: 'Validated • Send',
      icon: Icons.cloud_upload_outlined,
      iconSize: 14,
      color: Colors.orange[700]!,
      background: Colors.orange[50]!,
    );
  }

  Widget _buildParcelCard(BuildContext context, LandParcel parcel) {
    final localValidation = ref.watch(validationsByParcelProvider)[parcel.id];
    final badge = _statusBadgeFor(localValidation);
    final isSynced =
        localValidation != null && localValidation.syncStatus == 'synced';
    final needsSend = localValidation != null && !isSynced;
    final isSending =
        needsSend && _sendingValidationIds.contains(localValidation.id);

    return GestureDetector(
      onTap: () => _selectParcel(parcel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      parcel.identifierLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badge.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badge.icon,
                          color: badge.color,
                          size: badge.iconSize,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badge.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                parcel.owner,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                parcel.locationLabel.isNotEmpty
                    ? parcel.locationLabel
                    : 'PIN: ${parcel.pin}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                    tooltip: 'Remove from queue',
                    onPressed: () => _removeFromQueue(parcel),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => _selectParcel(parcel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isSynced)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Validated',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: isSending
                              ? null
                              : needsSend
                              ? () => _sendExistingValidation(localValidation)
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (_) =>
                                          _ValidationPage(parcel: parcel),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: isSending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  needsSend ? 'Send Validation' : 'Validate',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static app header shared by every screen (logo, notifications, profile)
class _MapXHeader extends StatelessWidget implements PreferredSizeWidget {
  const _MapXHeader();

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Image.asset(
                'assets/images/mapx_logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.borderColor,
                  child: Icon(Icons.person, color: Colors.grey, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page title row with an optional back button, shown below the static header
class _PageTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const _PageTitleBar({required this.title, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppTheme.textPrimaryColor,
              ),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Shared bottom navigation with Home, Map, and Sign Out only
class _BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMapTap;

  const _BottomNavBar({
    required this.currentIndex,
    this.onHomeTap,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 24),
          label: 'Home',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.map, size: 24), label: 'Map'),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout, size: 24),
          label: 'Sign Out',
        ),
      ],
      onTap: (index) async {
        switch (index) {
          case 0:
            onHomeTap?.call();
            break;
          case 1:
            onMapTap?.call();
            break;
          case 2:
            await ref.read(authStateProvider.notifier).logout();
            if (context.mounted) context.go('/login');
            break;
        }
      },
    );
  }
}

/// Validation screen for a specific parcel, with a toggleable RPU info card
class _ValidationPage extends ConsumerStatefulWidget {
  final LandParcel parcel;

  const _ValidationPage({required this.parcel});

  @override
  ConsumerState<_ValidationPage> createState() => _ValidationPageState();
}

class _ValidationPageState extends ConsumerState<_ValidationPage> {
  bool _isRPUExpanded = false;
  bool _isFetchingLocation = false;
  bool _isSaving = false;
  bool _isSending = false;
  double? _latitude;
  double? _longitude;
  final List<XFile> _photos = [];
  final Set<String> _existingPhotoPaths = {};
  String? _existingValidationId;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController();
    _loadExistingValidation();
  }

  /// Restore an unsent local draft for this parcel, if one exists, so a
  /// previously captured photo or coordinate isn't lost. Already-synced
  /// validations are left alone — a new visit starts a fresh record.
  Future<void> _loadExistingValidation() async {
    final repository = ref.read(validationRepositoryProvider);
    final result = await repository.getLatestValidationForParcel(
      parcelId: widget.parcel.id,
    );

    if (!mounted) return;

    result.match((failure) {}, (validation) {
      if (validation == null || validation.syncStatus == 'synced') return;

      setState(() {
        _existingValidationId = validation.id;
        _latitude = validation.latitude;
        _longitude = validation.longitude;
        _remarksController.text = validation.remarks ?? '';
        _existingPhotoPaths
          ..clear()
          ..addAll(validation.photoPaths);
        _photos
          ..clear()
          ..addAll(validation.photoPaths.map((path) => XFile(path)));
      });
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  /// Fetch the device's current GPS coordinates
  Future<void> _getCoordinate() async {
    setState(() => _isFetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to get location: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  /// Let the user capture a new photo or choose one from the gallery
  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 3 photos reached')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _photos.add(picked));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to pick photo: $e')));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  /// Create or update this parcel's local validation record with the
  /// current coordinates/remarks, then persist any newly captured photos
  /// (photos restored from an existing draft are not re-saved). Returns
  /// the validation id, or null if saving failed (a snackbar is shown).
  Future<String?> _persistLocally() async {
    final repository = ref.read(validationRepositoryProvider);
    final remarks = _remarksController.text.trim().isEmpty
        ? null
        : _remarksController.text.trim();

    String validationId;
    final existingId = _existingValidationId;

    if (existingId != null) {
      final result = await repository.updateValidation(
        validation: ValidationEntity(
          id: existingId,
          parcelId: widget.parcel.id,
          tdNumber: widget.parcel.tdNumber,
          status: ValidationStatus.valid,
          remarks: remarks,
          latitude: _latitude!,
          longitude: _longitude!,
          createdAt: DateTime.now(),
          photoIds: const [],
        ),
      );
      if (!mounted) return null;

      final failureMessage = result.match(
        (failure) => failure.message,
        (_) => null,
      );
      if (failureMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $failureMessage')),
        );
        return null;
      }
      validationId = existingId;
    } else {
      final result = await repository.createValidation(
        request: CreateValidationRequest(
          parcelId: widget.parcel.id,
          tdNumber: widget.parcel.tdNumber,
          status: ValidationStatus.valid,
          remarks: remarks,
          latitude: _latitude!,
          longitude: _longitude!,
          surveyDate: DateTime.now(),
        ),
      );
      if (!mounted) return null;

      final created = result.match<ValidationEntity?>((failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${failure.message}')),
        );
        return null;
      }, (validation) => validation);
      if (created == null) return null;

      validationId = created.id;
      _existingValidationId = created.id;
    }

    for (final photo in _photos) {
      if (_existingPhotoPaths.contains(photo.path)) continue;
      await repository.addPhotoToValidation(
        validationId: validationId,
        localPath: photo.path,
      );
      _existingPhotoPaths.add(photo.path);
    }

    return validationId;
  }

  /// Persist this field visit (coordinates, remarks, photos) to the local
  /// database so it can sync later, without requiring a network connection.
  Future<void> _saveLocal() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture the coordinate first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final validationId = await _persistLocally();

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (validationId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally. Will sync when online.')),
      );
      Navigator.of(context).pop();
    }
  }

  /// Save this field visit locally, then immediately try to submit it to
  /// MapX. If there's no connection right now, the record stays queued
  /// locally and the sync coordinator will resend it automatically once
  /// the device is back online.
  Future<void> _sendValidation() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture the coordinate first.')),
      );
      return;
    }

    setState(() => _isSending = true);

    final validationId = await _persistLocally();

    if (validationId == null) {
      if (mounted) setState(() => _isSending = false);
      return;
    }

    final repository = ref.read(validationRepositoryProvider);
    final uploadResult = await repository.uploadValidation(
      validationId: validationId,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    uploadResult.match(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No connection — saved locally, will send automatically when you\'re back online.',
            ),
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Validation sent')));
      },
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Image.asset(
                    'assets/images/mapx_logo.png',
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    _photos.isNotEmpty
                        ? Image.file(
                            File(_photos.first.path),
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 190,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.home,
                              size: 64,
                              color: Colors.grey[500],
                            ),
                          ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add Photo',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Photo thumbnails
              _buildThumbnailsRow(),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_photos.length} / 3 Photos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Get Coordinate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFetchingLocation ? null : _getCoordinate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: _isFetchingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    _isFetchingLocation
                        ? 'Fetching Location...'
                        : 'Get Coordinate',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Remarks
              const Text(
                'Remarks (Optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter field notes here...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Latitude / Longitude
              Row(
                children: [
                  Expanded(
                    child: _buildCoordinateField(
                      icon: Icons.public,
                      label: 'Latitude*',
                      value: _latitude?.toStringAsFixed(7) ?? '--',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCoordinateField(
                      icon: Icons.location_on_outlined,
                      label: 'Longitude*',
                      value: _longitude?.toStringAsFixed(6) ?? '--',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // RPU Information (toggleable)
              _buildRPUInfoCard(),
              const SizedBox(height: 20),

              // Save Local / Send Validation
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveLocal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text(
                        'Save Local',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendValidation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              size: 16,
                              color: Colors.white,
                            ),
                      label: const Text(
                        'Send Validation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the row of 3 photo thumbnail slots (captured photos, add slot, empty slots)
  Widget _buildThumbnailsRow() {
    final slots = <Widget>[];
    for (int i = 0; i < 3; i++) {
      if (i < _photos.length) {
        slots.add(_buildPhotoThumbnail(_photos[i], i));
      } else if (i == _photos.length) {
        slots.add(_buildAddThumbnail());
      } else {
        slots.add(_buildEmptyThumbnail());
      }
      if (i != 2) slots.add(const SizedBox(width: 10));
    }
    return Row(children: slots);
  }

  /// Selected photo thumbnail with a remove button
  Widget _buildPhotoThumbnail(XFile photo, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(photo.path),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Dashed "Add" thumbnail placeholder
  Widget _buildAddThumbnail() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue[50],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppTheme.primaryColor, size: 18),
            SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty grey thumbnail placeholder
  Widget _buildEmptyThumbnail() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 20),
    );
  }

  /// Latitude/Longitude input display box
  Widget _buildCoordinateField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Toggleable RPU Information card, populated with the real selected parcel
  Widget _buildRPUInfoCard() {
    final parcel = widget.parcel;
    final areaText = parcel.area != null
        ? NumberFormat('#,##0.00').format(parcel.area)
        : 'N/A';
    final valuationText = parcel.marketValue != null
        ? '₱${NumberFormat('#,##0.00').format(parcel.marketValue)}'
        : 'N/A';
    final classification =
        (parcel.landClass != null && parcel.landClass!.isNotEmpty)
        ? parcel.landClass!
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isRPUExpanded = !_isRPUExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RPU Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${parcel.tdNumber ?? parcel.id}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isRPUExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isRPUExpanded) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 4.0,
              ),
              child: Column(
                children: [
                  _buildRPUInfoRow('Owner', parcel.owner),
                  _buildRPUInfoRow('PIN', parcel.pin),
                  _buildRPUInfoRow('TD Number', parcel.tdNumber ?? 'N/A'),
                  _buildRPUInfoRow('Area (sqm)', areaText),
                  _buildRPUInfoRow(
                    'Classification',
                    null,
                    badge: classification,
                  ),
                  _buildRPUInfoRow('Valuation', valuationText, isLast: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A single labeled row inside the RPU Information card
  Widget _buildRPUInfoRow(
    String label,
    String? value, {
    String? badge,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else
                Text(
                  value ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}

/// Full-screen list of locally saved field validations, live-updated from
/// the local database, with a manual "sync now" action.
class _SavedValidationsPage extends ConsumerWidget {
  const _SavedValidationsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationsAsync = ref.watch(validationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MapXHeader(),
      body: Column(
        children: [
          _PageTitleBar(
            title: 'Saved Validations',
            onBack: () => Navigator.of(context).pop(),
            trailing: IconButton(
              icon: const Icon(Icons.sync, color: AppTheme.primaryColor),
              tooltip: 'Sync now',
              onPressed: () => _syncNow(context, ref),
            ),
          ),
          Expanded(
            child: validationsAsync.when(
              data: (validations) {
                if (validations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No saved validations yet. Records you save locally will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: validations.length,
                  itemBuilder: (context, index) =>
                      _buildValidationCard(validations[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Failed to load saved validations: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Manually trigger an upload attempt for every locally pending validation
  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Syncing...')));

    final synced = await ref
        .read(validationRepositoryProvider)
        .syncPendingValidations();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          synced > 0 ? 'Synced $synced validation(s)' : 'Nothing to sync',
        ),
      ),
    );
  }

  /// Build a card summarizing one saved validation
  Widget _buildValidationCard(Validation validation) {
    final isSynced = validation.syncStatus == 'synced';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    validation.tdNumber ?? validation.parcelId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSynced ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSynced
                            ? Icons.cloud_done
                            : Icons.cloud_upload_outlined,
                        size: 14,
                        color: isSynced
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSynced ? 'Synced' : 'Pending Sync',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSynced
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.my_location, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${validation.latitude.toStringAsFixed(6)}, ${validation.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (validation.remarks != null &&
                validation.remarks!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                validation.remarks!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, y • h:mm a').format(validation.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
