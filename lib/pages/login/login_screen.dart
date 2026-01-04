// pages/login/login_screen.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:camphor_forest/core/constants/route_constants.dart';
import 'package:camphor_forest/core/providers/core_providers.dart'; // ← apiServiceProvider
import 'package:camphor_forest/core/providers/auth_provider.dart';
import 'package:camphor_forest/core/providers/grade_provider.dart';
import 'package:camphor_forest/core/services/toast_service.dart';
import 'package:camphor_forest/core/widgets/theme_aware_scaffold.dart';
import 'package:camphor_forest/pages/classtable/providers/classtable_providers.dart';

/// 检测是否在 WASM 模式下运行
const bool kIsRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

/// 登录页面，提供用户身份验证和交互界面
///
/// 主要功能：
/// 1. 收集用户登录凭据（账号和密码）
/// 2. 执行登录验证
/// 3. 处理登录成功/失败的场景
/// 4. 收集设备和网络信息用于调试和安全
class LoginScreen extends ConsumerStatefulWidget {
  /// 构造函数，创建登录页面实例
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // 表单和输入控制器
  final _formKey = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // 用于读取表单字段状态，显示动画错误提示
  final _accountFieldKey = GlobalKey<FormFieldState>();
  final _passwordFieldKey = GlobalKey<FormFieldState>();

  // 状态变量
  bool _obscure = true; // 密码是否可见
  bool _agree = false; // 是否同意用户协议
  bool _loading = false; // 登录加载状态

  // 设备和网络信息
  String _ip = '', _loc = '', _system = '';

  @override
  void initState() {
    super.initState();
    // 初始化设备和网络信息
    _initDeviceInfo();
    _initIpInfo();
  }

  @override
  void dispose() {
    // 释放控制器资源，防止内存泄漏
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// 获取并打印详细的设备信息
  ///
  /// 收集信息包括：
  /// - 设备品牌
  /// - 设备型号
  /// - 操作系统版本
  ///
  /// 主要用于调试和日志记录
  Future<void> _initDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      String sysInfo;
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        sysInfo =
            '${info.browserName.name} (Web${kIsRunningWithWasm ? "/WASM" : "/JS"})';
      } else {
        final info = await plugin.deviceInfo;
        // 使用 device_info_plus 的通用方法获取设备信息
        final data = info.data;
        if (data.containsKey('brand') && data.containsKey('model')) {
          // Android
          sysInfo =
              '${data['brand']} ${data['model']} (Android ${data['version']?['release'] ?? 'Unknown'})';
        } else if (data.containsKey('name') &&
            data.containsKey('systemVersion')) {
          // iOS
          sysInfo = '${data['name']} (iOS ${data['systemVersion']})';
        } else {
          sysInfo = data.toString();
        }
      }
      AppLogger.debug('🛠 DeviceInfo: $sysInfo');
      if (!mounted) return;
      setState(() => _system = sysInfo);
    } catch (e, st) {
      AppLogger.debug('⚠️ _initDeviceInfo error: $e\n$st');
    }
  }

  /// 获取并打印 IP 地址和位置信息
  ///
  /// 通过 ApiService 获取网络信息
  /// 主要用于网络诊断和安全监控
  Future<void> _initIpInfo() async {
    try {
      final api = ref.read(apiServiceProvider);
      AppLogger.debug('🛠 Fetching IP info …');
      final info = await api.getIpInfo();
      AppLogger.debug('✅ Got IP info: ip=${info.ip}, loc=${info.loc}');
      if (!mounted) return;
      setState(() {
        _ip = info.ip;
        _loc = info.loc;
      });
    } catch (e, st) {
      AppLogger.debug('⚠️ _initIpInfo error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _ip = '获取失败';
        _loc = '获取失败';
      });
    }
  }

  /// 处理登录逻辑
  ///
  /// 执行步骤：
  /// 1. 验证表单
  /// 2. 检查是否同意用户协议
  /// 3. 调用登录方法
  /// 4. 处理登录结果（成功/失败）
  /// 5. 导航到相应页面或显示错误信息
  Future<void> _onLogin() async {
    // 验证表单输入
    if (!_formKey.currentState!.validate()) {
      // 触发界面重建以显示动画错误提示
      if (mounted) setState(() {});
      return;
    }

    // 检查用户协议
    if (!_agree) {
      _showToast('请先同意用户协议', Colors.orange);
      return;
    }

    // 设置加载状态
    setState(() => _loading = true);

    try {
      // 调用登录方法
      final account = _accountCtrl.text.trim();
      final password = _passwordCtrl.text.trim();

      // 使用 mounted 检查，防止异步操作中访问已销毁的 widget
      final ok = await ref.login(account, password);

      // 再次检查 mounted
      if (!mounted) return;

      // 获取错误信息
      final authState = ref.read(authProvider);
      final err = authState.errorMessage;

      // 根据登录结果处理
      if (ok) {
        // 登录成功，清除所有缓存的provider数据
        AppLogger.debug('🟢 登录成功，清除缓存并跳转到主页');
        // 清除课表相关的provider缓存
        ref.invalidate(classTableRepositoryProvider);
        // 清除成绩provider缓存
        ref.invalidate(gradeProvider);

        if (!mounted) return;
        context.go(RouteConstants.index);
      } else {
        // 登录失败，显示错误提示
        if (!mounted) return;
        _showToast(err ?? '登录失败，请检查账号和密码', Colors.red);
      }
    } catch (e, st) {
      // 处理异常情况
      AppLogger.debug('🔴 登录异常: $e\n$st');
      if (!mounted) return;
      _showToast('登录异常：${e.toString()}', Colors.red);
    } finally {
      // 恢复加载状态
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听认证状态，确保界面响应
    ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    // 保持白色文字的一致性，通过背景遮罩来提供对比度

    return ThemeAwareScaffold(
      pageType: PageType.loginPage,
      useBackground: true,
      backgroundImage: 'https://www.yumus.cn/api/?target=img&brand=bing&ua=m',
      addLightModeOverlay: true, // 在浅色模式下添加深色遮罩以提高对比度
      resizeToAvoidBottomInset: false, // 明确禁止键盘避让
      body: Stack(
        children: [
          // 登录表单居中 - 使用绝对定位避免键盘影响
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 学校 Logo
                      Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Colors.white, // 白色背景
                          shape: BoxShape.circle, // 圆形
                        ),
                        child: ClipOval(
                          child: SvgPicture.asset(
                            'assets/icons/swulogo.svg',
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                            placeholderBuilder: (_) =>
                                const CircularProgressIndicator(),
                            colorFilter: const ColorFilter.mode(
                              Color.fromRGBO(12, 63, 107, 1),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 登录表单
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 账号输入框
                            TextFormField(
                              key: _accountFieldKey,
                              controller: _accountCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                '请输入账号',
                                Icons.person,
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  (v?.isEmpty ?? true) ? '请输入账号' : null,
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: (() {
                                final err =
                                    _accountFieldKey.currentState?.errorText;
                                return (err == null || err.isEmpty)
                                    ? const SizedBox.shrink(
                                        key: ValueKey('empty'),
                                      )
                                    : Padding(
                                        key: const ValueKey('errorAccount'),
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          err,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                              })(),
                            ),
                            const SizedBox(height: 16),
                            // 密码输入框
                            TextFormField(
                              key: _passwordFieldKey,
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '请输入密码',
                                hintStyle: const TextStyle(
                                  color: Color(0xB3FFFFFF),
                                ),
                                filled: true,
                                fillColor: const Color(0x33FFFFFF),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (!mounted) return;
                                    setState(() => _obscure = !_obscure);
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                errorStyle: const TextStyle(
                                  height: 0,
                                  fontSize: 0,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  (v?.isEmpty ?? true) ? '请输入密码' : null,
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: (() {
                                final err =
                                    _passwordFieldKey.currentState?.errorText;
                                return (err == null || err.isEmpty)
                                    ? const SizedBox.shrink(
                                        key: ValueKey('empty'),
                                      )
                                    : Padding(
                                        key: const ValueKey('errorPwd'),
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          err,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                              })(),
                            ),
                            const SizedBox(height: 16),
                            // 用户协议复选框
                            Row(
                              children: [
                                Checkbox(
                                  value: _agree,
                                  splashRadius: 25,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  activeColor: Colors.greenAccent,
                                  checkColor: Colors.white,
                                  focusColor: Colors.white,
                                  onChanged: (v) {
                                    if (!mounted) return;
                                    setState(() => _agree = v ?? false);
                                  },
                                  fillColor: WidgetStateProperty.all(
                                    _agree
                                        ? Colors.greenAccent
                                        : Colors.transparent,
                                  ),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: '我已阅读并同意 ',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '《用户协议》',
                                          style: const TextStyle(
                                            color: Colors.lightBlueAccent,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              if (!mounted) return;
                                              context.push(
                                                RouteConstants.userAgreement,
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // 登录按钮
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                              child: _loading
                                  ? SizedBox(
                                      key: const ValueKey('loader'),
                                      width: _btnSize,
                                      height: _btnSize,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      key: const ValueKey('btn'),
                                      width: _btnSize,
                                      height: _btnSize,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          color: _agree
                                              ? Colors.blueAccent
                                              : Colors.grey.withAlpha(128),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: _onLogin,
                                          splashRadius: _btnSize / 2,
                                          icon: const Icon(
                                            Icons.arrow_forward,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 分隔线
                      Container(
                        width: size.width * 0.3,
                        height: 0.5,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 24),
                      // 诗句装饰
                      const Text(
                        '一处风声，看落花流萤，那粉色佳人，摇曳，摇曳。苍天赐予一个多情的梦，在花落之间。怎堪月痩影单，残风缠绵，好一个悲曲，绚烂绚烂。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 底部设备/IP 调试显示
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // WASM/JS 运行模式指示器
                if (kIsWeb)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kIsRunningWithWasm
                          ? Colors.green.withAlpha(180)
                          : Colors.orange.withAlpha(180),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          kIsRunningWithWasm ? Icons.bolt : Icons.javascript,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          kIsRunningWithWasm ? 'WASM' : 'JavaScript',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '设备: ${_system.isEmpty ? '加载中...' : _system}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  'IP: ${_ip.isEmpty ? '加载中...' : _ip}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  '位置: ${_loc.isEmpty ? '加载中...' : _loc}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 创建统一风格的输入框装饰
  ///
  /// 参数：
  /// - [hint] 输入框提示文本
  /// - [icon] 输入框前置图标
  /// - [hintColor] 提示文字颜色
  /// - [iconColor] 图标颜色
  /// - [fillColor] 填充颜色
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xB3FFFFFF)),
      filled: true,
      fillColor: const Color(0x33FFFFFF),
      prefixIcon: Icon(icon, color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(height: 0, fontSize: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }

  // 统一使用的圆形按钮尺寸
  static const double _btnSize = 72;

  // 统一显示提示信息
  void _showToast(String msg, Color bg) {
    ToastService.show(
      msg,
      backgroundColor: bg,
      textColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
