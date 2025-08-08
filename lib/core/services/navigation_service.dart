// lib/core/services/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  /// 全局 NavigatorKey
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// 给 MaterialApp.router 用来 showSnackBar 的 Key
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// 无 context 跳转到指定路由
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// 替换当前为新路由
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// 清栈并跳转
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }

  static void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }
}
