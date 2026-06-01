import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class PushNotificationManager {
  static bool _listenersInitialized = false;

  /// Request permissions and synchronize the FCM device push token with Firestore.
  static Future<void> syncTokenSubscription({
    required String userId,
    required bool enabled,
  }) async {
    try {
      if (enabled) {
        // 1. Request notification permissions from the OS
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          debugPrint('FCM Notification Permissions Granted');

          // 2. Fetch FCM registration token
          String? token;
          try {
            if (kIsWeb) {
              token = await FirebaseMessaging.instance.getToken();
            } else {
              token = await FirebaseMessaging.instance.getToken();
            }
          } catch (e) {
            debugPrint('FCM token generation warning (could be running in simulator): $e');
          }

          // 3. Register token persistently in Firestore
          if (token != null && token.isNotEmpty) {
            final platform = kIsWeb
                ? 'web'
                : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('tokens')
                .doc(token)
                .set({
              'token': token,
              'platform': platform,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'active': true,
            });

            // Sync with single fcmToken field on the user doc for Cloud Functions compatibility
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'fcmToken': token,
            });

            debugPrint('FCM device token registered in Firestore successfully');
          }
        } else {
          debugPrint('FCM Notification Permissions Denied');
        }
      } else {
        // User disabled notifications: clean up their token from Firestore
        await unregisterToken(userId: userId);
      }
    } catch (e) {
      debugPrint('FCM syncTokenSubscription error: $e');
    }
  }

  /// Remove the active device FCM token from the Firestore profile collection.
  static Future<void> unregisterToken({
    required String userId,
  }) async {
    try {
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .doc(token)
            .delete();

        // Clear fcmToken field if it matches the current token
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists && doc.data()?['fcmToken'] == token) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'fcmToken': FieldValue.delete(),
          });
        }

        debugPrint('FCM token deleted from Firestore successfully');
      }
    } catch (e) {
      debugPrint('FCM unregisterToken error: $e');
    }
  }

  /// Set up listeners for FCM token refresh, foreground message overlays, and tap deep-linking.
  static void initNotificationListeners() {
    if (_listenersInitialized) return;
    _listenersInitialized = true;

    // 1. Listen for device token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      try {
        final platform = kIsWeb
            ? 'web'
            : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tokens')
            .doc(newToken)
            .set({
          'token': newToken,
          'platform': platform,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'active': true,
        });

        // Sync with single fcmToken field on the user doc for Cloud Functions compatibility
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'fcmToken': newToken,
        });

        debugPrint('FCM token refreshed and saved successfully');
      } catch (e) {
        debugPrint('FCM token refresh persistence error: $e');
      }
    });

    // 2. Intercept foreground push events to display an elegant in-app SnackBar banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title ?? 'Новое уведомление / New notification',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF1E293B), // Premium dark theme color
          action: SnackBarAction(
            label: 'Открыть / Open',
            textColor: const Color(0xFF60A5FA), // Light blue link action
            onPressed: () {
              _handleNotificationTap(message);
            },
          ),
        ),
      );
    });

    // 3. Listen for message tap actions when the app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  /// Perform deep-link routing actions upon clicking on active notification alerts.
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      final classId = data['classId'] as String?;
      final roomId = data['roomId'] as String?;

      if (classId != null && navigatorKey.currentState != null) {
        debugPrint('Deep Link click parsed: classId=$classId, roomId=$roomId');
      }
    } catch (e) {
      debugPrint('Error routing on message tap: $e');
    }
  }
}
