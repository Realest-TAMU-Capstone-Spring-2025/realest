import 'package:flutter/material.dart';

void ignoreOverflowErrors() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
        // Ignore overflow errors
        debugPrint('Ignored Flutter overflow error: ${details.exceptionAsString()}');
      } else {
        FlutterError.dumpErrorToConsole(details);
      }
    };
}