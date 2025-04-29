import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents user settings stored in Firestore.
/// Subject to change as requirements evolve.
class Settings {
  /// Unique identifier for the settings document.
  final String id;

  /// ID of the user associated with these settings.
  final String userId;

  /// Indicates if dark mode is enabled.
  final bool isDarkMode;

  /// Indicates if notifications are enabled.
  final bool isNotificationsEnabled;

  /// Indicates if location services are enabled.
  final bool isLocationEnabled;

  /// Creates a [Settings] instance with required properties.
  Settings({
    required this.id,
    required this.userId,
    required this.isDarkMode,
    required this.isNotificationsEnabled,
    required this.isLocationEnabled,
  });

  /// Constructs a [Settings] from a Firestore document snapshot.
  /// Expects fields: userId, isDarkMode, isNotificationsEnabled, isLocationEnabled.
  factory Settings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Settings(
      id: doc.id,
      userId: data['userId'],
      isDarkMode: data['isDarkMode'],
      isNotificationsEnabled: data['isNotificationsEnabled'],
      isLocationEnabled: data['isLocationEnabled'],
    );
  }
}