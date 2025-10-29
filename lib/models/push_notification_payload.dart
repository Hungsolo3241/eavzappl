// lib/models/push_notification_payload.dart

import 'package:flutter/foundation.dart';

// Using @immutable is a good practice for model classes.
@immutable
class PushNotificationPayload {
  final String? senderId;
  final String type;
  final String? relatedItemId;
  final String? senderPhotoUrl;
  final String? senderName;
  final String? senderAge;
  final String? senderCity;
  final String? senderProfession;

  PushNotificationPayload({
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.senderAge,
    required this.senderCity,
    required this.senderProfession,
    required this.type,
    required this.relatedItemId,
  });

  // Factory constructor to create an instance from a map
  factory PushNotificationPayload.fromMap(Map<String, dynamic> data) {
    return PushNotificationPayload(
      senderId: data['senderId'] as String?,
      type: data['type'] as String? ?? 'unknown',
      relatedItemId: data['relatedItemId'] as String?,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      senderName: data['senderName'] as String?,
      senderAge: data['senderAge'] as String?,
      senderCity: data['senderCity'] as String?,
      senderProfession: data['senderProfession'] as String?,
    );
  }
}
