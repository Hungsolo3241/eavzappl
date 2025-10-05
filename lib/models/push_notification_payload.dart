// lib/models/push_notification_payload.dart

import 'package:flutter/foundation.dart';

// Using @immutable is a good practice for model classes.
@immutable
class PushNotificationPayload {
  final String type;
  final String? relatedItemId;
  final String? senderPhotoUrl;
  final String? senderName;
  // --- ADDED THE MISSING FIELDS ---
  final String? senderAge;
  final String? senderCity;
  final String? senderProfession;

  const PushNotificationPayload({
    required this.type,
    this.relatedItemId,
    this.senderPhotoUrl,
    this.senderName,
    this.senderAge,
    this.senderCity,
    this.senderProfession,
  });

  // Factory constructor to create an instance from a map
  factory PushNotificationPayload.fromMap(Map<String, dynamic> data) {
    return PushNotificationPayload(
      type: data['type'] as String? ?? 'unknown',
      relatedItemId: data['relatedItemId'] as String?,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      senderName: data['senderName'] as String?,
      // --- MAP THE MISSING FIELDS ---
      senderAge: data['senderAge'] as String?,
      senderCity: data['senderCity'] as String?,
      senderProfession: data['senderProfession'] as String?,
    );
  }
}
