import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wraps a widget with necessary providers for testing.
Widget wrapWithProviders({
  required Widget child,
  List<ChangeNotifierProvider> providers = const [],
}) {
  if (providers.isEmpty) {
    return MaterialApp(home: child);
  }
  return MultiProvider(
    providers: providers,
    child: MaterialApp(home: child),
  );
}

/// Wraps a widget with MaterialApp for testing.
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(home: child);
}

/// Wraps a widget with MaterialApp.router for route testing.
Widget wrapWithRouter(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}
