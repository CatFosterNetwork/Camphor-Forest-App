import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastService {
  const ToastService._();

  static Future<bool?> show(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    ToastGravity gravity = ToastGravity.BOTTOM,
    double fontSize = 16,
  }) {
    Fluttertoast.cancel();
    final toastLength = _resolveLength(duration);
    final resolvedBackground = backgroundColor ?? Colors.black87;
    final resolvedTextColor = textColor ?? Colors.white;

    return Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      backgroundColor: resolvedBackground,
      textColor: resolvedTextColor,
      fontSize: fontSize,
    );
  }

  static Future<bool?> cancel() {
    return Fluttertoast.cancel();
  }

  static Toast _resolveLength(Duration? duration) {
    if (duration == null) {
      return Toast.LENGTH_SHORT;
    }
    return duration.inMilliseconds >= 3000
        ? Toast.LENGTH_LONG
        : Toast.LENGTH_SHORT;
  }
}
