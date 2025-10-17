import 'dart:ui';
import 'package:flutter/material.dart';

/// BackdropFilter修复工具类
/// 解决Flutter 3.16+版本中BackdropFilter在橡皮筋效果时失效的问题
class BackdropFilterFix {
  /// 创建一个修复了橡皮筋效果问题的BackdropFilter
  /// 使用Stack结构确保模糊效果作为背景层
  static Widget createFixedBackdropFilter({
    required ImageFilter filter,
    required Widget child,
    BlendMode blendMode = BlendMode.srcOver,
  }) {
    return ClipRect(
      child: Stack(
        children: [
          // 背景模糊层
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: filter,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 前景内容
          child,
        ],
      ),
    );
  }

  /// 创建带背景的模糊容器，确保内容在模糊层之上
  static Widget createBackgroundBlur({
    required Widget child,
    required Widget backgroundChild,
    double sigmaX = 10.0,
    double sigmaY = 10.0,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          // 背景内容（被模糊的部分）
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
              child: backgroundChild,
            ),
          ),
          // 前景内容（清晰显示）
          child,
        ],
      ),
    );
  }

  /// 创建一个带模糊效果的容器，解决BackdropFilter问题
  static Widget createBlurContainer({
    required Widget child,
    double sigmaX = 10.0,
    double sigmaY = 10.0,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    Widget container = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    // 使用ImageFiltered替代BackdropFilter
    container = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: container,
      ),
    );

    return container;
  }

  /// 为ScrollView提供固定的滚动物理效果，避免橡皮筋效果
  static ScrollPhysics getFixedScrollPhysics() {
    return const _FixedScrollPhysics();
  }
}

/// 修复的滚动物理效果，避免StretchingOverscrollIndicator
class _FixedScrollPhysics extends ScrollPhysics {
  const _FixedScrollPhysics({super.parent});

  @override
  _FixedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _FixedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 完全禁用边界弹性效果，避免StretchingOverscrollIndicator
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if (position.outOfRange) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }
      assert(end != null);
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end!,
        velocity,
        tolerance: tolerance,
      );
    }
    if (velocity.abs() < tolerance.velocity) {
      return null;
    }
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
