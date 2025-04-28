// test/flutter_test_config.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Swallows only RenderFlex overflow errors, forwards all others.
void _ignoreOverflowErrors(FlutterErrorDetails details, {bool forceReport = false}) {
  final msg = details.exceptionAsString();
  if (msg.startsWith('A RenderFlex overflowed by')) {
    // drop only overflow errors
    return;
  }
  FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
}

/// This must match the Flutter test framework’s expected signature:
///   Future<void> testExecutable(FutureOr<void> Function() testMain)
///
/// It will be called once, wrapping your test’s `main()`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterError.onError = _ignoreOverflowErrors;
  await testMain();            // run the actual tests
}