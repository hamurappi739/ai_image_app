import 'package:flutter/material.dart';

import '../models/user_balance.dart';

/// Provides drawer access and shared balance state inside [MainShell].
class AppNavigationScope extends InheritedWidget {
  const AppNavigationScope({
    super.key,
    required this.openDrawer,
    required this.showUserBalance,
    required this.balanceLoading,
    required this.balanceLoadFailed,
    this.userBalance,
    required super.child,
  });

  final VoidCallback openDrawer;
  final bool showUserBalance;
  final UserBalance? userBalance;
  final bool balanceLoading;
  final bool balanceLoadFailed;

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
    return openDrawer != oldWidget.openDrawer ||
        showUserBalance != oldWidget.showUserBalance ||
        userBalance != oldWidget.userBalance ||
        balanceLoading != oldWidget.balanceLoading ||
        balanceLoadFailed != oldWidget.balanceLoadFailed;
  }
}
