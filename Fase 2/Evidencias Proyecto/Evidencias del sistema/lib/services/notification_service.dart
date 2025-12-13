import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  // Singleton sencillo
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String defaultTimeZone = 'America/Santiago';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final location = tz.getLocation(defaultTimeZone);
      tz.setLocalLocation(location);
    } catch (e) {
      debugPrint('No se pudo fijar la zona horaria $defaultTimeZone: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("Notificacion tocada: ${response.payload}");
      },
    );
  }

  static Future<void> showNow({
    required String title,
    String? body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'agendai_channel_id',
      'Recordatorios AgendAI',
      channelDescription: 'Canal principal para recordatorios',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> schedule({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledUtc,
    DateTimeComponents? matchDateTimeComponents,
    int prealertMinutes = 0,
  }) async {
    final when = tz.TZDateTime.from(scheduledUtc, tz.local);

    if (Platform.isAndroid) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestExactAlarmsPermission();
    }

    const androidDetails = AndroidNotificationDetails(
      'agendai_channel_id',
      'Recordatorios AgendAI',
      channelDescription: 'Canal principal para recordatorios',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    Future<void> _programar(
      int targetId,
      String targetTitle,
      String? targetBody,
      tz.TZDateTime targetWhen,
    ) async {
      try {
        await _plugin.zonedSchedule(
          targetId,
          targetTitle,
          targetBody,
          targetWhen,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        debugPrint("Ok. Notificacion programada (exacta) para: $targetWhen");
      } catch (e) {
        debugPrint("Error programando exacta ($targetId): $e. Probando inexacta...");
        try {
          await _plugin.zonedSchedule(
            targetId,
            targetTitle,
            targetBody,
            targetWhen,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
          );
          debugPrint("Ok. Notificacion programada (inexacta) para: $targetWhen");
        } catch (e2) {
          debugPrint("Error critico al programar notificacion ($targetId): $e2");
        }
      }
    }

    // Notificacion principal
    await _programar(id, title, body, when);

    // Aviso anticipado fijo (por defecto 15 min cuando se pida)
    if (prealertMinutes > 0) {
      final preWhen = when.subtract(Duration(minutes: prealertMinutes));
      if (preWhen.isAfter(tz.TZDateTime.now(tz.local))) {
        await _programar(
          _prealertId(id),
          "En $prealertMinutes min: $title",
          body,
          preWhen,
        );
      } else {
        debugPrint("Se omitio prealerta porque la hora ya paso: $preWhen (id $id)");
      }
    }
  }

  static int _prealertId(int baseId) => baseId * 1000 + 1;

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
