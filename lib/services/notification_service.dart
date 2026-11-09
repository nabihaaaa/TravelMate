import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'travelmate_trip_reminders',
        'Trip Reminders',
        channelDescription: 'Notifications for trips and safety check-ins',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

  // Initialize notifications and the device time zone.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  }

  // Request permission to display notifications.
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.requestNotificationsPermission() ?? false;
  }

  // Show an immediate test trip notification.
  Future<void> showTripReminder({
    required String tripName,
    required String destination,
  }) async {
    await _plugin.show(
      100,
      'Your adventure awaits!',
      'Get ready for $tripName in $destination.',
      _notificationDetails,
    );
  }

  // Schedule a notification for a selected trip date and time.
  Future<void> scheduleTripReminder({
    required int tripId,
    required String tripName,
    required String destination,
    required DateTime reminderDate,
  }) async {
    if (!reminderDate.isAfter(DateTime.now())) {
      throw ArgumentError('Reminder must be scheduled in the future.');
    }

    await _plugin.zonedSchedule(
      tripId,
      'Your adventure awaits!',
      'Get ready for $tripName in $destination.',
      tz.TZDateTime.from(reminderDate, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Cancel a scheduled trip reminder.
  Future<void> cancelTripReminder(int tripId) async {
    await _plugin.cancel(tripId);
  }

  // Schedule a daily safety check-in reminder.
  Future<void> scheduleDailyCheckIn({
    required int tripId,
    required String tripName,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();

    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      200000 + tripId,
      'TravelMate Safety Check-in',
      'Remember to check in with your trusted contact for $tripName.',
      tz.TZDateTime.from(scheduled, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel a daily safety check-in reminder.
  Future<void> cancelDailyCheckIn(int tripId) async {
    await _plugin.cancel(200000 + tripId);
  }
}
