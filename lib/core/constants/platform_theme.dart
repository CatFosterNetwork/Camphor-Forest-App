// lib/core/constants/platform_theme.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// 同时持有 Material 和 Cupertino 主题工厂
class PlatformThemeData {
  final ThemeData Function(BuildContext context) android;
  final CupertinoThemeData Function(BuildContext context) ios;

  const PlatformThemeData({required this.android, required this.ios});
}

class PlatformTheme {
  /// 亮色主题
  static PlatformThemeData getLightTheme(BuildContext context) {
    return const PlatformThemeData(
      android: _lightMaterialTheme,
      ios: _lightCupertinoTheme,
    );
  }

  /// 暗色主题
  static PlatformThemeData getDarkTheme(BuildContext context) {
    return const PlatformThemeData(
      android: _darkMaterialTheme,
      ios: _darkCupertinoTheme,
    );
  }

  // ─── Material 主题 ────────────────────────────────────────────────────────

  static ThemeData _lightMaterialTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _darkMaterialTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  // ─── Cupertino 主题 ──────────────────────────────────────────────────────

  static CupertinoThemeData _lightCupertinoTheme(BuildContext context) {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: CupertinoColors.systemBlue,
    );
  }

  static CupertinoThemeData _darkCupertinoTheme(BuildContext context) {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: CupertinoColors.systemBlue,
    );
  }

  // ─── 通用 AppBar 工厂 ────────────────────────────────────────────────────

  /// 创建一个跨平台 AppBar，自动映射到 MaterialAppBarData 和 CupertinoNavigationBarData
  static PlatformAppBar createAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    return PlatformAppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      // Material 端直接用 actions 列表
      material: (_, _) => MaterialAppBarData(actions: actions),
      // Cupertino 端要用 title + trailing
      cupertino: (_, _) => CupertinoNavigationBarData(
        // CupertinoNavigationBarData 的属性是 title :contentReference[oaicite:0]{index=0}
        title: Text(title),
        trailing: actions != null
            ? Row(mainAxisSize: MainAxisSize.min, children: actions)
            : null,
      ),
    );
  }

  // ─── 通用 Scaffold 工厂 ──────────────────────────────────────────────────

  /// 创建一个跨平台 Scaffold，自动为 iOS 端注入 CupertinoNavigationBar
  static Widget createScaffold({
    required BuildContext context,
    PlatformAppBar? appBar,
    required Widget body,
    PlatformNavBar? bottomNavBar,
    Widget? floatingActionButton,
    bool iosContentPadding = true,
    bool iosContentBottomPadding = true,
  }) {
    return PlatformScaffold(
      appBar: appBar,
      body: body,
      bottomNavBar: bottomNavBar,
      iosContentPadding: iosContentPadding,
      iosContentBottomPadding: iosContentBottomPadding,
      material: (_, _) =>
          MaterialScaffoldData(floatingActionButton: floatingActionButton),
      cupertino: (ctx, _) => CupertinoPageScaffoldData(
        // 通过 appBar.createCupertinoWidget(ctx) 直接拿到 ObstructingPreferredSizeWidget :contentReference[oaicite:1]{index=1}
        navigationBar: appBar?.createCupertinoWidget(ctx),
      ),
    );
  }

  // ─── 通用 ElevatedButton 工厂 （无需改动）────────────────────────────────

  static PlatformElevatedButton createElevatedButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return PlatformElevatedButton(
      onPressed: onPressed,
      child: child,
      material: (_, _) => MaterialElevatedButtonData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          disabledBackgroundColor: Colors.grey,
        ),
      ),
      cupertino: (_, _) => CupertinoElevatedButtonData(
        color: CupertinoColors.systemBlue,
        disabledColor: CupertinoColors.systemGrey,
      ),
    );
  }

  // ─── 通用 TextField 工厂 ─────────────────────────────────────────────────

  /// 注意：PlatformTextField 不支持 validator，需要表单校验请用 PlatformTextFormField
  static PlatformTextField createTextField({
    required BuildContext context,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? prefix,
    Widget? suffix,
  }) {
    return PlatformTextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      material: (_, _) => MaterialTextFieldData(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      cupertino: (_, _) => CupertinoTextFieldData(
        placeholder: hintText,
        prefix: prefix,
        suffix: suffix,
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
