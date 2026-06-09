import 'package:flutter/material.dart';

/// Provides [openDrawer] to descendants inside [MainShell] (below nested Scaffolds).
class AppNavigationScope extends InheritedWidget {
  const AppNavigationScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static AppNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigationScope>();
  }

  static VoidCallback openDrawerOf(BuildContext context) {
    final scope = maybeOf(context);
    if (scope != null) {
      return scope.openDrawer;
    }
    return () => Scaffold.of(context).openDrawer();
  }

  @override
  bool updateShouldNotify(AppNavigationScope oldWidget) {
    return openDrawer != oldWidget.openDrawer;
  }
}
