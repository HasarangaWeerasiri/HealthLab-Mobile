import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    print('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> scheduleDailyReminder({
    required String experimentId,
    required String experimentTitle,
    required TimeOfDay time,
  }) async {
    if (!_initialized) await initialize();

    // Cancel any existing reminder for this experiment
    await cancelReminder(experimentId);

    // Schedule the daily reminder
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Reminders to log daily experiment data',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      _getNotificationId(experimentId),
      'Time to log your data! 📊',
      'Add your daily data to "$experimentTitle" experiment',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      payload: experimentId,
    );

    // Save reminder settings
    await _saveReminderSettings(experimentId, time);
  }

  Future<void> cancelReminder(String experimentId) async {
    if (!_initialized) await initialize();
    
    await _notifications.cancel(_getNotificationId(experimentId));
    await _removeReminderSettings(experimentId);
  }

  Future<bool> isReminderActive(String experimentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('reminder_$experimentId');
  }

  Future<TimeOfDay?> getReminderTime(String experimentId) async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_${experimentId}_hour');
    final minute = prefs.getInt('reminder_${experimentId}_minute');
    
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  int _getNotificationId(String experimentId) {
    // Generate a unique ID based on experiment ID
    return experimentId.hashCode.abs() % 1000000;
  }

  Future<void> _saveReminderSettings(String experimentId, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_$experimentId', true);
    await prefs.setInt('reminder_${experimentId}_hour', time.hour);
    await prefs.setInt('reminder_${experimentId}_minute', time.minute);
  }

  Future<void> _removeReminderSettings(String experimentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminder_$experimentId');
    await prefs.remove('reminder_${experimentId}_hour');
    await prefs.remove('reminder_${experimentId}_minute');
  }

  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }
}
