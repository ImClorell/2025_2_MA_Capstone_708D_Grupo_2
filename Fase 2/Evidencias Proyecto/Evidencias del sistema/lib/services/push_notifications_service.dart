import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agendai/services/notification_service.dart';
import 'package:agendai/core/supabase_client.dart';

Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await NotificationService.init();
  await NotificationService.showNow(
    title: message.notification?.title ?? 'AgendAI',
    body: message.notification?.body ?? '',
    payload: message.data['id'],
  );
}

class PushNotificationsService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static StreamSubscription<AuthState>? _authSub;
  static bool _started = false;

  static Future<void> init() async {
    if (_started) return;
    _started = true;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Vincular token al usuario cuando inicie sesi¢n / cambie sesi¢n
    _authSub = Supa.client.auth.onAuthStateChange.listen((event) {
      _refreshTokenForCurrentUser();
    });

    // Registrar token actual
    await _refreshTokenForCurrentUser();

    // Manejo de tokens rotados
    _fcm.onTokenRefresh.listen(_saveToken);

    // Mensajes en foreground -> usamos notificacion local para mostrarlos
    FirebaseMessaging.onMessage.listen((message) {
      NotificationService.showNow(
        title: message.notification?.title ?? 'AgendAI',
        body: message.notification?.body ?? '',
        payload: message.data['id'],
      );
    });
  }

  static Future<void> _refreshTokenForCurrentUser() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = Supa.client.auth.currentUser;
    if (user == null) return;

    await Supa.client.from('user_devices').upsert({
      'user_id': user.id,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> dispose() async {
    await _authSub?.cancel();
    _started = false;
  }
}
