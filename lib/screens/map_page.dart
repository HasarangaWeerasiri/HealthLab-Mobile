import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/danger_zone.dart';
import '../providers/danger_zone_provider.dart';
import '../widgets/danger_level_bottom_sheet.dart';
import '../widgets/danger_zone_info_sheet.dart';
import '../widgets/filter_chip_widget.dart';

/// Main map page for displaying and managing danger zones
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Default location (Colombo, Sri Lanka) - fallback if location unavailable
  static const LatLng _defaultLocation = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _setupAnimations();
  }

  /// Initializes the danger zone provider
  Future<void> _initializeProvider() async {
    final provider = context.read<DangerZoneProvider>();
    await provider.initialize();

    // Move map to current location if available
    if (mounted && provider.currentLocation != null) {
      _mapController.move(provider.currentLocation!, 13.0);
    }
  }

  /// Sets up animations for UI elements
  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<DangerZoneProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          return Stack(
            children: [
              _buildMap(provider),
              _buildFilterChips(provider),
              if (provider.errorMessage != null)
                _buildErrorBanner(provider),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  /// Builds the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Health Safety Map',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'About',
          onPressed: _showAboutDialog,
        ),
      ],
    );
  }

  /// Builds the loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading map...'),
        ],
      ),
    );
  }

  /// Builds the main map widget
  Widget _buildMap(DangerZoneProvider provider) {
    final center = provider.currentLocation ?? _defaultLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.0,
        minZoom: 3.0,
        maxZoom: 18.0,
        onTap: (tapPosition, point) => _handleMapTap(point, provider),
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.healthlab.app',
          maxZoom: 19,
        ),
        // Danger zone markers
        MarkerLayer(
          markers: _buildMarkers(provider),
        ),
        // Current location marker
        if (provider.currentLocation != null)
          MarkerLayer(
            markers: [_buildCurrentLocationMarker(provider.currentLocation!)],
          ),
      ],
    );
  }

  /// Builds markers for all danger zones
  List<Marker> _buildMarkers(DangerZoneProvider provider) {
    return provider.filteredDangerZones.map((zone) {
      return Marker(
        point: zone.position,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showDangerZoneInfo(zone, provider),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: _getDangerLevelColor(zone.dangerLevel),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _getDangerLevelColor(zone.dangerLevel)
                        .withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Builds the current location marker
  Marker _buildCurrentLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: const Center(
          child: Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Builds filter chips for danger levels
  Widget _buildFilterChips(DangerZoneProvider provider) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterChipWidget(
                label: 'High',
                emoji: '🟥',
                isSelected: provider.activeFilters.contains(DangerLevel.high),
                onSelected: () => provider.toggleFilter(DangerLevel.high),
              ),
              FilterChipWidget(
                label: 'Medium',
                emoji: '🟨',
                isSelected: provider.activeFilters.contains(DangerLevel.medium),
                onSelected: () => provider.toggleFilter(DangerLevel.medium),
              ),
              FilterChipWidget(
                label: 'Low',
                emoji: '🟩',
                isSelected: provider.activeFilters.contains(DangerLevel.low),
                onSelected: () => provider.toggleFilter(DangerLevel.low),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds error banner
  Widget _buildErrorBanner(DangerZoneProvider provider) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red.shade900),
                onPressed: provider.clearError,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds floating action buttons
  Widget _buildFloatingActionButtons() {
    return Consumer<DangerZoneProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                heroTag: 'refresh',
                mini: true,
                onPressed: () => _refreshLocation(provider),
                tooltip: 'Refresh Location',
                child: const Icon(Icons.my_location),
              ),
            ),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                onPressed: _zoomIn,
                tooltip: 'Zoom In',
                child: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                onPressed: _zoomOut,
                tooltip: 'Zoom Out',
                child: const Icon(Icons.remove),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handles map tap to add new danger zone
  void _handleMapTap(LatLng point, DangerZoneProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DangerLevelBottomSheet(
        onLevelSelected: (level) async {
          final success = await provider.addDangerZone(
            position: point,
            dangerLevel: level,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${level.emoji} ${level.displayName} danger zone added'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  /// Shows danger zone information
  void _showDangerZoneInfo(DangerZone zone, DangerZoneProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DangerZoneInfoSheet(
        zone: zone,
        onEdit: (newLevel) async {
          final success = await provider.updateDangerZone(
            id: zone.id,
            dangerLevel: newLevel,
          );

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Danger zone updated to ${newLevel.displayName}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onDelete: () async {
          final success = await provider.deleteDangerZone(zone.id);

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Danger zone deleted'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  /// Refreshes current location
  Future<void> _refreshLocation(DangerZoneProvider provider) async {
    await provider.refreshLocation();
    if (provider.currentLocation != null) {
      _mapController.move(provider.currentLocation!, 13.0);
    }
  }

  /// Zooms in the map
  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  /// Zooms out the map
  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  /// Shows about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Health Safety Map'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap anywhere on the map to add a danger zone marker.'),
            SizedBox(height: 8),
            Text('🟥 High - Critical health risk'),
            Text('🟨 Medium - Moderate health risk'),
            Text('🟩 Low - Minor health risk'),
            SizedBox(height: 8),
            Text('Tap a marker to view, edit, or delete it.'),
            SizedBox(height: 8),
            Text('Use the filter chips to show/hide danger levels.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Gets color for danger level
  Color _getDangerLevelColor(DangerLevel level) {
    switch (level) {
      case DangerLevel.high:
        return Colors.red;
      case DangerLevel.medium:
        return Colors.orange;
      case DangerLevel.low:
        return Colors.green;
    }
  }
}
