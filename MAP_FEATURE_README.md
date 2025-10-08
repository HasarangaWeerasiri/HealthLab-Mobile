# Health Safety Map Feature - Integration Guide

## 📋 Overview

This module provides a complete OpenStreetMap-based danger zone management system for the HealthLab mobile app. Users can mark, view, edit, and filter health risk zones on an interactive map.

## 🎯 Features Implemented

✅ **OpenStreetMap Integration** - Uses `flutter_map` plugin (no Google Maps API needed)  
✅ **Real-time Location** - Automatically centers map on user's current location  
✅ **Danger Zone Markers** - Tap anywhere to add color-coded risk markers  
✅ **Three Risk Levels**:
- 🟥 **High** (Red) - Critical health risk
- 🟨 **Medium** (Yellow/Orange) - Moderate health risk  
- 🟩 **Low** (Green) - Minor health risk

✅ **Persistent Storage** - All markers saved locally using `shared_preferences`  
✅ **Edit & Delete** - Tap markers to view info, change level, or remove  
✅ **Smart Filtering** - Toggle visibility by risk level  
✅ **Material 3 Design** - Modern UI with smooth animations  
✅ **Dart 3.8.1 Compatible** - No features from later versions used

## 📁 Project Structure

```
lib/
├── models/
│   └── danger_zone.dart          # Data model for danger zones
├── services/
│   ├── location_service.dart     # Handles GPS and permissions
│   └── storage_service.dart      # Local data persistence
├── providers/
│   └── danger_zone_provider.dart # State management with Provider
├── screens/
│   └── map_page.dart             # Main map screen
├── widgets/
│   ├── danger_level_bottom_sheet.dart  # Add new zone UI
│   ├── danger_zone_info_sheet.dart     # View/edit existing zone
│   └── filter_chip_widget.dart         # Filter toggle chips
└── main.dart                     # Updated with Provider setup
```

## 🚀 Quick Integration

### Step 1: Install Dependencies

Run this command in your project root:

```bash
flutter pub get
```

### Step 2: Configure Permissions

#### **Android** (`android/app/src/main/AndroidManifest.xml`)

Add these permissions inside `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### **iOS** (`ios/Runner/Info.plist`)

Add these keys inside `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby health risk zones</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show nearby health risk zones</string>
```

### Step 3: Navigate to Map

From any screen in your app, navigate to the map using:

```dart
// Simple navigation
Navigator.pushNamed(context, '/map');

// OR with MaterialPageRoute
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const MapPage()),
);
```

## 💡 Usage Examples

### Example 1: Add Map Button to Dashboard

```dart
// In your dashboard or home screen
ElevatedButton.icon(
  onPressed: () => Navigator.pushNamed(context, '/map'),
  icon: const Icon(Icons.map),
  label: const Text('View Safety Map'),
)
```

### Example 2: Direct Navigation from Splash

```dart
// In splash_screen.dart or any initial screen
Future.delayed(const Duration(seconds: 2), () {
  Navigator.pushReplacementNamed(context, '/map');
});
```

### Example 3: Bottom Navigation Integration

```dart
int _currentIndex = 0;

final List<Widget> _pages = [
  const DashboardScreen(),
  const MapPage(),  // Add map as a tab
  const ProfileScreen(),
];

BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
)
```

## 🎨 Customization

### Change Default Location

Edit `map_page.dart` line 25:

```dart
// Default is Colombo, Sri Lanka
static const LatLng _defaultLocation = LatLng(6.9271, 79.8612);

// Change to your preferred location
static const LatLng _defaultLocation = LatLng(YOUR_LAT, YOUR_LNG);
```

### Customize Colors

Edit the `_getDangerLevelColor` method in `map_page.dart`:

```dart
Color _getDangerLevelColor(DangerLevel level) {
  switch (level) {
    case DangerLevel.high:
      return Colors.red;        // Change to your color
    case DangerLevel.medium:
      return Colors.orange;     // Change to your color
    case DangerLevel.low:
      return Colors.green;      // Change to your color
  }
}
```

### Change Map Style

The map uses OpenStreetMap by default. To use a different tile provider, edit `map_page.dart` line 130:

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  // Other options:
  // Humanitarian: 'https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png'
  // Dark mode: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
  // Light mode: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
)
```

## 🔧 API Reference

### DangerZoneProvider Methods

```dart
// Get provider instance
final provider = Provider.of<DangerZoneProvider>(context, listen: false);

// Add a danger zone
await provider.addDangerZone(
  position: LatLng(6.9271, 79.8612),
  dangerLevel: DangerLevel.high,
  description: 'Optional description',
);

// Update a danger zone
await provider.updateDangerZone(
  id: 'zone_id',
  dangerLevel: DangerLevel.medium,
);

// Delete a danger zone
await provider.deleteDangerZone('zone_id');

// Clear all zones
await provider.clearAllZones();

// Refresh location
await provider.refreshLocation();

// Toggle filter
provider.toggleFilter(DangerLevel.high);
```

## 🐛 Troubleshooting

### Issue: Map not loading

**Solution**: Check internet connection. OpenStreetMap tiles require internet access.

### Issue: Location not detected

**Solutions**:
1. Ensure location permissions are granted in device settings
2. Enable GPS/Location Services on the device
3. Check that permissions are added to `AndroidManifest.xml` and `Info.plist`

### Issue: Markers not persisting

**Solution**: Ensure `shared_preferences` is properly initialized. The app handles this automatically.

### Issue: Build errors after adding dependencies

**Solution**: Run these commands:
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Testing Checklist

- [ ] Map loads and displays OpenStreetMap tiles
- [ ] Current location marker appears (blue circle)
- [ ] Tapping map opens danger level selection sheet
- [ ] All three danger levels can be added
- [ ] Markers appear with correct colors
- [ ] Tapping markers shows info sheet
- [ ] Editing danger level works
- [ ] Deleting markers works
- [ ] Filter chips toggle marker visibility
- [ ] Markers persist after app restart
- [ ] Zoom in/out buttons work
- [ ] Refresh location button works

## 🔐 Privacy & Security

- **No external API keys required** - Uses free OpenStreetMap tiles
- **Local storage only** - Data stored on device using `shared_preferences`
- **No cloud sync** - All data remains on the user's device
- **Location permission** - Only requested when needed, not stored permanently

## 📦 Dependencies Used

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^6.1.0 | OpenStreetMap rendering |
| `latlong2` | ^0.9.0 | Latitude/longitude handling |
| `geolocator` | ^11.0.0 | GPS location services |
| `shared_preferences` | ^2.2.2 | Local data storage |
| `provider` | ^6.1.1 | State management |
| `intl` | ^0.19.0 | Date formatting |

All packages are compatible with **Dart 3.8.1** and Flutter SDK.

## 🤝 Integration with Existing Features

This map module is **completely isolated** and won't interfere with:
- Sign Up / Login flows
- User Profile management
- Dashboard screens
- Firebase authentication
- Any other existing features

Simply add navigation to `MapPage()` wherever needed in your app.

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all permissions are configured
3. Ensure dependencies are installed (`flutter pub get`)
4. Check console logs for specific error messages

## 🎓 Learning Resources

- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [OpenStreetMap Tile Servers](https://wiki.openstreetmap.org/wiki/Tile_servers)
- [Geolocator Plugin Guide](https://pub.dev/packages/geolocator)
- [Provider State Management](https://pub.dev/packages/provider)

---

**Built with ❤️ for HealthLab Mobile App**  
Compatible with Dart 3.8.1 | Material 3 Design | Production Ready
