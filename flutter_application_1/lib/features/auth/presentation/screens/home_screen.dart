import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_theme.dart';

/// RPU (Property Unit) model
class RPUItem {
  final String id;
  final String type;
  final String owner;
  final String address;
  final String status;
  bool isSelected;

  RPUItem({
    required this.id,
    required this.type,
    required this.owner,
    required this.address,
    required this.status,
    this.isSelected = false,
  });
}

/// Pending parcel validation model
class ParcelValidation {
  final String id;
  final String owner;
  final String address;
  final String status;

  ParcelValidation({
    required this.id,
    required this.owner,
    required this.address,
    required this.status,
  });
}

/// Activity item model
class ActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}

/// Home/Dashboard screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample activity data
    final activities = [
      ActivityItem(
        type: 'node_added',
        title: 'Node Added',
        subtitle: 'Coordinates: 40.7128° N, 74.0060° W',
        time: '18:42 AM',
        icon: Icons.add_circle,
        iconColor: AppTheme.successColor,
      ),
      ActivityItem(
        type: 'validation_passed',
        title: 'Validation Passed',
        subtitle: 'Sector 75 boundary check completed',
        time: '09:15 AM',
        icon: Icons.check_circle,
        iconColor: AppTheme.successColor,
      ),
      ActivityItem(
        type: 'sync_error',
        title: 'Sync Error',
        subtitle: 'Failed to upload offline batch #4402',
        time: 'Yesterday',
        icon: Icons.sync_problem,
        iconColor: AppTheme.errorColor,
      ),
      ActivityItem(
        type: 'photo_captured',
        title: 'Photo Captured',
        subtitle: 'Field documentation for parcel P-2024-158',
        time: '2 days ago',
        icon: Icons.camera_alt,
        iconColor: AppTheme.infoColor,
      ),
    ];

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
                          const Text(
                            '78%',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Completed',
                            style: TextStyle(
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
                          value: 0.78,
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
                          const Text(
                            '12',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                    icon: const Icon(Icons.tune, color: AppTheme.textSecondaryColor),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityItem(activity);
                },
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
              child: Icon(
                activity.icon,
                color: activity.iconColor,
                size: 20,
              ),
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

/// Add RPU full-screen page
class _AddRPUPage extends StatefulWidget {
  const _AddRPUPage();

  @override
  State<_AddRPUPage> createState() => _AddRPUPageState();
}

class _AddRPUPageState extends State<_AddRPUPage> {
  static const Color _typeColor = Color(0xFFB8860B);

  late TextEditingController _searchController;
  late List<RPUItem> rpuList;
  late List<RPUItem> filteredList;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Sample RPU data
    rpuList = [
      RPUItem(
        id: '28-06-8883-62983',
        type: 'Commercial',
        owner: 'Acme Corp LLC',
        address: '124 Industrial Pkwy, Sector 4',
        status: 'Available',
      ),
      RPUItem(
        id: '28-06-8883-62984',
        type: 'Residential',
        owner: 'John Doe',
        address: '45 Maple Street, Apt 2B',
        status: 'In Queue',
      ),
      RPUItem(
        id: '28-06-8883-10293',
        type: 'Mixed Use',
        owner: 'Community Development Corp',
        address: 'Lake Drive, Sector 2',
        status: 'Available',
      ),
    ];

    filteredList = rpuList;
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredList = rpuList;
      } else {
        filteredList = rpuList
            .where((item) =>
                item.id.toLowerCase().contains(query) ||
                item.owner.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = rpuList.where((item) => item.isSelected).length;

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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle
                const Text(
                  'Search and select property units to add to your validation queue.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by RPU ID or Owner Name...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
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

                // RPU List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final rpu = filteredList[index];
                      return _buildRPUItem(rpu);
                    },
                  ),
                ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Added $selectedCount RPU(s) to queue'),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
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
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
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

  /// Build individual RPU card
  Widget _buildRPUItem(RPUItem rpu) {
    final isAvailable = rpu.status == 'Available';
    final statusColor = isAvailable ? AppTheme.primaryColor : Colors.grey[600]!;
    final statusBg = isAvailable ? Colors.blue[50]! : Colors.grey[200]!;
    final statusIcon = isAvailable ? Icons.check_circle : Icons.pause_circle_outline;

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
            // RPU ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rpu.id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rpu.type,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rpu.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
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
                    rpu.owner,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Address
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rpu.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 10),

            // Select row
            GestureDetector(
              onTap: () {
                setState(() {
                  rpu.isSelected = !rpu.isSelected;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rpu.isSelected ? 'Selected' : 'Select',
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
                      color: rpu.isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: rpu.isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[400]!,
                        width: 1.5,
                      ),
                    ),
                    child: rpu.isSelected
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

/// A tappable parcel polygon shown on the map view
class _MapParcel {
  final String rpuId;
  final String unitNumber;
  final String address;
  final List<LatLng> points;
  final LatLng center;

  _MapParcel({
    required this.rpuId,
    required this.unitNumber,
    required this.address,
    required this.points,
    required this.center,
  });
}

/// Map View full-screen page showing pending validations on the map
class _MapViewPage extends StatefulWidget {
  const _MapViewPage();

  @override
  State<_MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<_MapViewPage> {
  _MapParcel? _selectedParcel;
  LatLng? _myLocation;
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(8.9483, 125.5406);

  final List<_MapParcel> _mapParcels = [
    _MapParcel(
      rpuId: 'RPU-2023-0891',
      unitNumber: 'B-4',
      address: 'Caraga State University - Main Campus',
      points: const [
        LatLng(8.9487, 125.5401),
        LatLng(8.9487, 125.5411),
        LatLng(8.9479, 125.5411),
        LatLng(8.9479, 125.5401),
      ],
      center: const LatLng(8.9483, 125.5406),
    ),
    _MapParcel(
      rpuId: 'RPU-2023-0892',
      unitNumber: 'C-2',
      address: 'Ampayon, Butuan City',
      points: const [
        LatLng(8.9498, 125.5420),
        LatLng(8.9498, 125.5430),
        LatLng(8.9490, 125.5430),
        LatLng(8.9490, 125.5420),
      ],
      center: const LatLng(8.9494, 125.5425),
    ),
    _MapParcel(
      rpuId: 'RPU-2023-0893',
      unitNumber: 'A-7',
      address: 'Libertad, Butuan City',
      points: const [
        LatLng(8.9468, 125.5388),
        LatLng(8.9468, 125.5398),
        LatLng(8.9460, 125.5398),
        LatLng(8.9460, 125.5388),
      ],
      center: const LatLng(8.9464, 125.5393),
    ),
  ];

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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
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
      final intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  void _handleMapTap(LatLng point) {
    _MapParcel? tapped;
    for (final parcel in _mapParcels) {
      if (_pointInPolygon(point, parcel.points)) {
        tapped = parcel;
        break;
      }
    }
    setState(() => _selectedParcel = tapped);
  }

  /// Select a parcel from the list and pan the map to it
  void _selectParcelFromList(ParcelValidation parcel) {
    _MapParcel? match;
    for (final p in _mapParcels) {
      if (p.rpuId == parcel.id) {
        match = p;
        break;
      }
    }
    if (match == null) return;
    setState(() => _selectedParcel = match);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(match!.center, 17.5);
    });
  }

  /// Straight-line distance from the user to the selected parcel, in meters
  double? get _distanceToSelected {
    if (_myLocation == null || _selectedParcel == null) return null;
    return Geolocator.distanceBetween(
      _myLocation!.latitude,
      _myLocation!.longitude,
      _selectedParcel!.center.latitude,
      _selectedParcel!.center.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parcels = [
      ParcelValidation(
        id: 'RPU-2023-0891',
        owner: 'Sarah Jenkins',
        address: '1244 Sycamore Drive, Parcel B-4',
        status: 'Pending',
      ),
      ParcelValidation(
        id: 'RPU-2023-0892',
        owner: 'Marcus Thorne',
        address: '87 Birchwood Lane, Parcel C-2',
        status: 'Pending',
      ),
      ParcelValidation(
        id: 'RPU-2023-0893',
        owner: 'Elena Vasquez',
        address: '502 Windmill Court, Parcel A-7',
        status: 'Pending',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MapXHeader(),
      body: Column(
        children: [
          _PageTitleBar(
            title: 'Map View',
            onBack: () => Navigator.of(context).pop(),
          ),
          // Map area
          _selectedParcel != null
              ? Expanded(child: _buildMapStack())
              : SizedBox(height: 220, child: _buildMapStack()),

          if (_selectedParcel != null)
            _buildSelectedUnitBar(context)
          else
            // Pending validations list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                      child: ListView.builder(
                        itemCount: parcels.length,
                        itemBuilder: (context, index) {
                          return _buildParcelCard(context, parcels[index]);
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

  /// Map with parcel polygons, selection marker, and floating controls
  Widget _buildMapStack() {
    final distance = _distanceToSelected;
    final minutes = distance == null ? null : (distance / 80).ceil().clamp(1, 999);

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
              onTap: (tapPosition, point) => _handleMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mapx.validator',
              ),
              PolygonLayer(
                polygons: _mapParcels.map((parcel) {
                  final isSelected = _selectedParcel == parcel;
                  return Polygon(
                    points: parcel.points,
                    color: isSelected
                        ? AppTheme.successColor.withValues(alpha: 0.45)
                        : AppTheme.successColor.withValues(alpha: 0.15),
                    borderColor: AppTheme.successColor,
                    borderStrokeWidth: isSelected ? 3 : 2,
                  );
                }).toList(),
              ),
              if (_selectedParcel != null && _myLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_myLocation!, _selectedParcel!.center],
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
                  if (_selectedParcel != null)
                    Marker(
                      point: _selectedParcel!.center,
                      width: 160,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.errorColor, size: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              _selectedParcel!.address,
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
                  if (_selectedParcel != null && _myLocation != null && distance != null)
                    Marker(
                      point: LatLng(
                        (_myLocation!.latitude + _selectedParcel!.center.latitude) / 2,
                        (_myLocation!.longitude + _selectedParcel!.center.longitude) / 2,
                      ),
                      width: 90,
                      height: 34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            const Icon(Icons.directions_walk, size: 14, color: AppTheme.primaryColor),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                parcel.rpuId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const _ValidationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Validate',
              style: TextStyle(
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
  Widget _buildParcelCard(BuildContext context, ParcelValidation parcel) {
    return GestureDetector(
      onTap: () => _selectParcelFromList(parcel),
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
                Text(
                  parcel.id,
                  style: const TextStyle(
                    fontSize: 13,
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
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.red[300], size: 8),
                      const SizedBox(width: 4),
                      Text(
                        parcel.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[400],
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
              parcel.address,
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const _ValidationPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Validate',
                    style: TextStyle(
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
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
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
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.borderColor,
                child: Icon(Icons.person, color: Colors.grey, size: 18),
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

  const _PageTitleBar({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared bottom navigation with Home, Map, and Sign Out only
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMapTap;

  const _BottomNavBar({
    required this.currentIndex,
    this.onHomeTap,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home, size: 24), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map, size: 24), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.logout, size: 24), label: 'Sign Out'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            onHomeTap?.call();
            break;
          case 1:
            onMapTap?.call();
            break;
          case 2:
            context.go('/login');
            break;
        }
      },
    );
  }
}

/// Validation screen for a specific parcel, with a toggleable RPU info card
class _ValidationPage extends StatefulWidget {
  const _ValidationPage();

  @override
  State<_ValidationPage> createState() => _ValidationPageState();
}

class _ValidationPageState extends State<_ValidationPage> {
  bool _isRPUExpanded = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;
  final List<XFile> _photos = [];
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController();
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to get location: $e')),
      );
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
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppTheme.primaryColor),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() => _photos.add(picked));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick photo: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
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
                    icon: const Icon(Icons.arrow_back,
                        color: AppTheme.textPrimaryColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Image.asset(
                    'assets/images/mapx_logo.png',
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppTheme.textPrimaryColor),
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
                            child: Icon(Icons.home, size: 64, color: Colors.grey[500]),
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
                              const Icon(Icons.add_a_photo_outlined,
                                  size: 16, color: AppTheme.primaryColor),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white, size: 18),
                  label: Text(
                    _isFetchingLocation ? 'Fetching Location...' : 'Get Coordinate',
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
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text(
                        'Save Local',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Validation sent')),
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send, size: 16, color: Colors.white),
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

  /// Toggleable RPU Information card
  Widget _buildRPUInfoCard() {
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RPU Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ID: 2006000302844',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isRPUExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isRPUExpanded) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Column(
                children: [
                  _buildRPUInfoRow('Owner', 'GABORNO, NICOLAS C.'),
                  _buildRPUInfoRow('Area (sqm)', '1,250.00'),
                  _buildRPUInfoRow(
                    'Classification',
                    null,
                    badge: 'Residential',
                  ),
                  _buildRPUInfoRow('Valuation', '\$450,000', isLast: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A single labeled row inside the RPU Information card
  Widget _buildRPUInfoRow(String label, String? value,
      {String? badge, bool isLast = false}) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
