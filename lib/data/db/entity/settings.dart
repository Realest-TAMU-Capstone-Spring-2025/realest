import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//user settings
//subject to change
class Settings {
  final String id;
  final String userId;
  final bool isDarkMode;
  final bool isNotificationsEnabled;
  final bool isLocationEnabled;

  Settings({
    required this.id,
    required this.userId,
    required this.isDarkMode,
    required this.isNotificationsEnabled,
    required this.isLocationEnabled,
  });

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