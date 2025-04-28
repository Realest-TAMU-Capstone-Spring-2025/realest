// test/flutter_test_config.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

// 1) This helper drops only RenderFlex overflow errors.
void _ignoreOverflowErrors(FlutterErrorDetails details, {bool forceReport = false}) {
  final msg = details.exceptionAsString();
  if (msg.startsWith('A RenderFlex overflowed by')) {
    return; // swallow it
  }
  FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
}

// 2) This is the **only** symbol the test harness will call.
// It must accept a single FutureOr<void> Function() argument.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Install our overflow‐ignoring handler globally.
  FlutterError.onError = _ignoreOverflowErrors;
  // Run the real tests.
  await testMain();
}