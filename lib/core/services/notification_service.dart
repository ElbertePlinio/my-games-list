import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:picklog/core/data/services/http/i_http_client.dart';

/// Service that manages Firebase Cloud Messaging (FCM) integration.
///
/// Responsibilities:
/// - Requesting notification permissions
/// - Displaying foreground notifications via flutter_local_notifications
/// - Sending the FCM token to the backend for push delivery
/// - Emitting navigation events when a notification tap contains a route
class NotificationService {
  NotificationService({required IHttpClient httpClient})
    : _httpClient = httpClient;

  final IHttpClient _httpClient;
  // Accessed lazily so construction does not throw in test environments
  // where Firebase is not initialized.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _navigationController = StreamController<String>.broadcast();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  bool _initialized = false;
  // Bumped on every disable(); an in-flight initialize() compares against it so
  // a revoke/logout mid-setup cancels before the token is sent or listeners are
  // attached (otherwise it would PATCH the token and listen after consent off).
  int _generation = 0;

  /// Stream of route strings to navigate to when a notification is tapped.
  Stream<String> get navigationStream => _navigationController.stream;

  /// Requests permission, registers the FCM token with the backend, and starts
  /// listening for messages.
  ///
  /// LGPD: this is only invoked once push consent is granted **and** the user
  /// is authenticated (so the backend PATCH /users/me/fcm-token can succeed
  /// instead of 401-ing at cold start). It must never run on app launch.
  Future<void> initialize() async {
    // Push notifications (FCM + flutter_local_notifications) are not supported
    // on web in this app, so skip all setup there.
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    // Capture the generation this setup belongs to. disable() bumps it, so if a
    // revoke/logout lands mid-setup we bail before sending the token or
    // attaching listeners (which would leak collection after consent is off).
    final generation = _generation;
    bool isStale() => generation != _generation;

    // Auto-init is off by default (native config) and after every disable().
    // Turn it back on only now that push consent is granted, so the SDK does
    // not recreate the token behind our back.
    await _messaging.setAutoInitEnabled(true);

    // 1. Request permissions
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (isStale()) return;

    // 2. Initialize flutter_local_notifications for foreground display
    await _initLocalNotifications();
    if (isStale()) return;

    // 3. Get FCM token and send to backend
    final token = await _messaging.getToken();
    if (isStale()) return;
    if (token != null) await _sendTokenToBackend(token);
    if (isStale()) return;

    // 4. Listen for token refreshes
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _sendTokenToBackend,
    );

    // 5. Foreground message handler (show local notification)
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    // 6. Notification tap: app was in background, user tapped notification
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationTap);

    // 7. Notification tap: app was terminated, opened from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (isStale()) return;
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _navigationController.add(details.payload!);
        }
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && (route as String).isNotEmpty) {
      _navigationController.add(route);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _httpClient.patch(
        '/users/me/fcm-token',
        data: {'fcm_token': token, 'platform': _platform},
      );
    } catch (_) {
      // Non-critical: silently ignore failures
    }
  }

  /// Stops push collection on consent revocation: cancels message/token-refresh
  /// subscriptions, deletes the FCM token on-device, and asks the backend to
  /// drop the stored token so it stops delivering. Idempotent and safe to call
  /// even if [initialize] never ran.
  Future<void> disable() async {
    if (kIsWeb) return;
    // Invalidate any in-flight initialize() so it stops before sending the
    // token or attaching listeners.
    _generation++;
    await _cancelMessageSubscriptions();
    _initialized = false;
    try {
      // Stop the SDK from re-minting a token after we delete it below.
      await _messaging.setAutoInitEnabled(false);
      await _deleteTokenFromBackend();
      await _messaging.deleteToken();
    } catch (_) {
      // Best-effort teardown; never block consent revocation on FCM errors.
    }
  }

  Future<void> _deleteTokenFromBackend() async {
    try {
      await _httpClient.delete('/users/me/fcm-token');
    } catch (_) {
      // Non-critical: backend may already lack the token.
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  Future<void> _cancelMessageSubscriptions() async {
    await _tokenRefreshSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _navigationController.close();
  }
}
