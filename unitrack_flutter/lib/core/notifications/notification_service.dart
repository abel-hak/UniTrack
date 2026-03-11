import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> scheduleAssignmentReminder({
    required int id,
    required String title,
    required String courseCode,
    required DateTime dueAt,
  }) async {
    final reminderTime = dueAt.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Assignment Due Soon',
      '$courseCode: $title is due in 1 hour',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'assignments',
          'Assignment Reminders',
          channelDescription: 'Reminders for upcoming assignment deadlines',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleExamReminder({
    required int id,
    required String courseCode,
    required String kind,
    required DateTime startsAt,
  }) async {
    final reminderTime = startsAt.subtract(const Duration(hours: 24));
    if (reminderTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      id + 100000,
      'Exam Tomorrow',
      '$courseCode ${_capitalize(kind)} is tomorrow at ${_formatTime(startsAt)}',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exams',
          'Exam Reminders',
          channelDescription: 'Reminders for upcoming exams',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $amPm';
  }
}
