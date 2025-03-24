import 'package:flutter/material.dart';

class MouseRegionProvider extends ChangeNotifier {
  final Map<String, bool> _hoverStates = {};

  bool isHovered(String key) => _hoverStates[key] ?? false;

  void setHover(String key, bool isHovered) {
    _hoverStates[key] = isHovered;
    notifyListeners();
  }

  void clearHover(String key) {
    _hoverStates.remove(key);
    notifyListeners();
  }
}