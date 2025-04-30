import 'package:flutter/material.dart';

/// Provides hover state management for multiple widgets.
/// Used to track whether specific UI elements are being hovered over.
class MouseRegionProvider extends ChangeNotifier {
  // Stores hover states keyed by widget identifiers.
  final Map<String, bool> _hoverStates = {};

  /// Returns true if the widget identified by [key] is currently hovered.
  bool isHovered(String key) => _hoverStates[key] ?? false;

  /// Sets the hover state for a specific [key].
  void setHover(String key, bool isHovered) {
    _hoverStates[key] = isHovered;
    notifyListeners();
  }

  /// Clears the hover state for a specific [key].
  void clearHover(String key) {
    _hoverStates.remove(key);
    notifyListeners();
  }
}
