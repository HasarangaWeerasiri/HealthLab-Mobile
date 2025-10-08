# 🚀 Quick Setup Instructions

## Step 1: Install Dependencies

Open terminal in your project root and run:

```bash
flutter pub get
```

## Step 2: Configure Android Permissions

Open `android/app/src/main/AndroidManifest.xml` and add these lines inside the `<manifest>` tag (before `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Your file should look like this:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application
        android:label="healthlab"
        ...>
        ...
    </application>
</manifest>
```

## Step 3: Configure iOS Permissions

Open `ios/Runner/Info.plist` and add these keys inside the `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby health risk zones</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show nearby health risk zones</string>
```

## Step 4: Test the Map

### Option A: Navigate from any existing screen

Add this button to any screen:

```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/map'),
  child: const Text('Open Map'),
)
```

### Option B: Test directly from main.dart

Temporarily change line 32 in `main.dart` from:

```dart
home: const SplashScreen(),
```

to:

```dart
home: const MapPage(),
```

Then run:

```bash
flutter run
```

**Don't forget to change it back after testing!**

## Step 5: Verify Everything Works

When you run the app, you should see:

✅ Map loads with OpenStreetMap tiles  
✅ Blue location marker appears (after granting permission)  
✅ Filter chips at the top (High, Medium, Low)  
✅ Floating action buttons on the right  
✅ Tapping the map opens a bottom sheet to select danger level  
✅ Markers appear when you add danger zones  
✅ Tapping markers shows info with edit/delete options  

## 🐛 Troubleshooting

### Map doesn't load
- Check internet connection
- Verify `INTERNET` permission is added

### Location not working
- Grant location permission when prompted
- Enable GPS on your device
- Verify location permissions are added to manifest/plist

### Build errors
Run these commands:
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Next Steps

1. **Integrate into your app**: Add navigation to MapPage from your dashboard or menu
2. **Customize**: Change colors, default location, or map style (see MAP_FEATURE_README.md)
3. **Test thoroughly**: Try adding, editing, and deleting markers
4. **Check persistence**: Close and reopen the app to verify markers are saved

## 📚 Documentation

- Full documentation: `MAP_FEATURE_README.md`
- Navigation examples: `lib/examples/map_navigation_example.dart`

## ✅ Ready to Go!

Your map feature is now ready to use. Simply navigate to it from anywhere in your app using:

```dart
Navigator.pushNamed(context, '/map');
```

Happy coding! 🎉
