
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    channelDescription: 'Notifications for upcoming trips',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  // Initialize notifications and the device time zone.
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );
  }

  // Request permission to display notifications.
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    return await android?.requestNotificationsPermission() ?? false;
  }

  // Existing immediate notification (keep this for testing).
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

  // NEW: Schedule a notification for a selected date and time.
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

  // NEW: Cancel a scheduled reminder.
  Future<void> cancelTripReminder(int tripId) async {
    await _plugin.cancel(tripId);
  }
}
