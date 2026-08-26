import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../main.dart';

/// The chat destination encoded in an FCM data payload.
///
/// Older chat notifications did not include `destination`, so a room ID is
/// also accepted for backwards compatibility.
class ChatNotificationTarget {
  const ChatNotificationTarget({
    this.classId,
    this.roomId,
    this.topicId,
    this.messageId,
    this.destination,
  });

  factory ChatNotificationTarget.fromData(Map<String, dynamic> data) {
    return ChatNotificationTarget(
      classId: _nonBlankString(data['classId']),
      roomId: _nonBlankString(data['roomId']),
      topicId: _nonBlankString(data['topicId']),
      messageId: _nonBlankString(data['messageId']),
      destination: _nonBlankString(data['destination'] ?? data['type']),
    );
  }

  final String? classId;
  final String? roomId;
  final String? topicId;
  final String? messageId;
  final String? destination;

  bool get isChat => destination == 'chat' || roomId != null;
}

String? _nonBlankString(Object? value) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? null : result;
}

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
            debugPrint(
              'FCM token generation warning (could be running in simulator): $e',
            );
          }

          // 3. Register token persistently in Firestore
          if (token != null && token.isNotEmpty) {
            final platform = kIsWeb
                ? 'web'
                : (defaultTargetPlatform == TargetPlatform.iOS
                      ? 'ios'
                      : 'android');

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
                .update({'fcmToken': token});

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
  static Future<void> unregisterToken({required String userId}) async {
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
              .update({'fcmToken': FieldValue.delete()});
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
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
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
      final target = ChatNotificationTarget.fromData(message.data);

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: InkWell(
            onTap: target.isChat
                ? () => unawaited(_handleNotificationTap(message))
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
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
                          notification.title ??
                              'Новое уведомление / New notification',
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
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF1E293B), // Premium dark theme color
          action: target.isChat
              ? SnackBarAction(
                  label: 'Открыть / Open',
                  textColor: const Color(0xFF60A5FA),
                  onPressed: () => unawaited(_handleNotificationTap(message)),
                )
              : null,
        ),
      );
    });

    // 3. Listen for message tap actions when the app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      unawaited(_handleNotificationTap(message));
    });

    // 4. Handle a notification that launched a terminated mobile app.
    unawaited(_handleInitialNotification());
  }

  static Future<void> _handleInitialNotification() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) await _handleNotificationTap(message);
    } catch (e) {
      debugPrint('Could not process initial notification: $e');
    }
  }

  /// Opens the exact class chat encoded by an FCM notification. A room-only
  /// notification is resolved via its Firestore metadata, which also supports
  /// old payloads and the teachers' lounge.
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      final target = ChatNotificationTarget.fromData(message.data);
      if (!target.isChat) return;

      final navigationContext = navigatorKey.currentContext;
      if (navigationContext == null) {
        debugPrint('Notification navigation deferred: navigator unavailable');
        return;
      }

      final scope = AppScope.of(navigationContext);
      if (!scope.appState.isTeacher && !scope.appState.isStudent) {
        debugPrint('Notification chat route ignored for a non-chat role');
        return;
      }
      var classId = target.classId;
      if (classId == null && target.roomId == 'global_teachers_lounge') {
        classId = 'teachers_lounge';
      }

      if (classId == null && target.roomId != null) {
        final room = await scope.repository.firestore
            .collection('rooms')
            .doc(target.roomId)
            .get();
        final metadata = room.data()?['metadata'];
        if (metadata is Map) {
          classId = _nonBlankString(metadata['classId']);
        }
      }

      if (classId == null) {
        debugPrint(
          'Notification ignored: no accessible class for room ${target.roomId}',
        );
        return;
      }

      final isTeachersLounge = classId == 'teachers_lounge';
      scope.appState.openChat(
        classId: classId,
        topicId: target.topicId,
        selectClass: !isTeachersLounge,
      );
      if (scope.appState.isTeacher) {
        scope.appState.setTeacherTabIndex(isTeachersLounge ? 3 : 2);
      }
      debugPrint(
        'Notification routed to chat: classId=$classId, roomId=${target.roomId}, messageId=${target.messageId}',
      );
    } catch (e) {
      debugPrint('Error routing on message tap: $e');
    }
  }

  /// Sends a push notification payload via the Vercel Backend endpoint.
  static Future<void> sendPushNotification({
    List<String>? tokens,
    List<String>? userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if ((tokens == null || tokens.isEmpty) &&
        (userIds == null || userIds.isEmpty))
      return;
    try {
      const proxyUrl = String.fromEnvironment(
        'GOOGLE_DRIVE_PROXY_URL',
        defaultValue: 'https://vercel-talentum-backend.vercel.app',
      );
      if (proxyUrl.isEmpty) return;

      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      await Dio().post(
        '$proxyUrl/api/notifications/send',
        data: {
          if (tokens != null && tokens.isNotEmpty) 'tokens': tokens,
          if (userIds != null && userIds.isNotEmpty) 'userIds': userIds,
          'title': title,
          'body': body,
          'data': data,
        },
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
    } catch (e) {
      debugPrint('Push send error: $e');
    }
  }
}
