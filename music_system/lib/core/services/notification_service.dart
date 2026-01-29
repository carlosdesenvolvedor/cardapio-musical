import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // IMPORTANT: For Web production, you MUST provide a real VAPID Key from Firebase Console
  // Project Settings -> Cloud Messaging -> Web Push certificates
  // If this is empty, getToken() might fail on some browsers.
  static const String _vapidKey =
      "BCCx14Mk3UNNgq8SFxaE6b8B0iCbh9sCfGbXE7B9yz5qgvhY7b6uL03IWyJJjQbN-LtBVSYklLEb7hr_kKR2_jk";

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // Set to false to force explicit dialog
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');

      // Get the token with VAPID key for Web
      try {
        String? token;
        if (kIsWeb) {
          token =
              await _fcm.getToken(vapidKey: _vapidKey != "" ? _vapidKey : null);
        } else {
          token = await _fcm.getToken();
        }
        debugPrint("Firebase Messaging Token: $token");
      } catch (e) {
        debugPrint("Error getting FCM token: $e");
      }
    } else {
      debugPrint(
          'User declined or has not yet granted notification permission');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification?.title}');
      }
    });

    // When the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
    });
  }

  Future<void> saveTokenToFirestore(String userId) async {
    int retries = 3;
    while (retries > 0) {
      try {
        String? token;
        if (kIsWeb) {
          token =
              await _fcm.getToken(vapidKey: _vapidKey != "" ? _vapidKey : null);
        } else {
          token = await _fcm.getToken();
        }

        if (token != null) {
          await _firestore.collection('users').doc(userId).set({
            'fcmToken': token,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint("FCM Token saved successfully for $userId");
          break; // Success
        } else {
          debugPrint("FCM Token is null, skipping save");
          break;
        }
      } catch (e) {
        debugPrint(
            "Error saving token to Firestore (retry ${4 - retries}): $e");
        retries--;
        if (retries > 0) {
          await Future.delayed(Duration(seconds: 4 - retries));
        }
      }
    }
  }

  Future<void> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
  }) async {
    // Note: Real push from client-to-client is highly restricted for security.
    // Usually, you call a Firebase Cloud Function here.
    // For now, we simulate and log. In production, this would trigger the Function.
    debugPrint(
        'PUSH REQUEST -> To: $recipientToken | Title: $title | Body: $body');

    // If you have a Cloud Function, you could do:
    // await dio.post('YOUR_CLOUD_FUNCTION_URL', data: {...});
  }
}

// Global static handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
