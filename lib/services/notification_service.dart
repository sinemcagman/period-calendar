import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/db_helper.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs in the background. We can check the database to see if next period is in 2 days.
    // This logic ensures notifications fire even if the app wasn't opened.
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      
      final cyclesData = await db.query('cycles', orderBy: 'start_date DESC', limit: 3);
      if (cyclesData.isEmpty) return Future.value(true);
      
      // Basic 28-day gap fallback calculation for demo purposes in background
      DateTime latestStart = DateTime.parse(cyclesData.first['start_date'] as String);
      DateTime predictedNext = latestStart.add(const Duration(days: 28)); // We will refine this logic in Provider
      
      DateTime now = DateTime.now();
      int daysUntil = predictedNext.difference(now).inDays;
      
      if (daysUntil == 2) {
        // Time to trigger notification
        await NotificationService.showNotification(
          id: 100,
          title: 'Regl Yaklaştı',
          body: 'Tahmini döngünüzün başlamasına 2 gün kaldı. Hazırlıklarınızı gözden geçirin.',
        );
      }
    } catch(e) {
      print(e);
    }
    return Future.value(true);
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
         // Handle notification tap
      },
    );

    // Initialize Workmanager for BG tasks
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Register a periodic task
    Workmanager().registerPeriodicTask(
      "period-tracker-check",
      "checkCyclesTask",
      frequency: const Duration(hours: 24),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'period_tracker_channel',
      'Regl Takibi Bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF4D6D),
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String recurrenceType = 'none',
  }) async {
    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    const NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'period_tracker_reminders',
        'Özel Hatırlatıcılar',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    if (recurrenceType == 'daily') {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else if (recurrenceType == 'weekly') {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } else if (recurrenceType == 'monthly') {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } else {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }
  
  static Future<void> cancelTask(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
