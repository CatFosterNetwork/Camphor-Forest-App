import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camphor_forest/core/models/user_model.dart';
import 'package:camphor_forest/core/services/api_service.dart';
import 'package:camphor_forest/core/config/services/unified_config_service.dart';
import 'package:camphor_forest/core/services/widget_service.dart';

class UserService {
  static const _userInfoKey = 'userInfo';
  static const jwtKey = 'jwt';

  final FlutterSecureStorage _secureStorage;
  final UnifiedConfigService _configService;
  final ApiService _apiService;

  UserModel _userInfo = UserModel.empty();
  String _jwt = '';

  UserService(this._secureStorage, this._configService, this._apiService);

  /// 从本地存储初始化用户信息和 JWT
  Future<void> initialize() async {
    debugPrint('💾 开始从本地存储初始化用户信息和 JWT');

    // 调用 check() 检查 JWT 是否有效
    final isJwtValid = await check();

    if (isJwtValid) {
      debugPrint('✅ 本地 JWT 验证成功');

      // 如果 JWT 有效，初始化用户信息
      initUser();
    } else {
      debugPrint('❌ 本地 JWT 无效，跳过初始化');
      // 如果 JWT 无效，跳过后续步骤
    }
  }

  /// 仅从本地缓存加载用户信息（不调用API）
  Future<UserModel> loadUserFromCache() async {
    debugPrint('💾 仅从本地缓存加载用户信息');

    // 从本地存储加载用户信息
    final localUserInfo = await _secureStorage.read(key: _userInfoKey);
    if (localUserInfo != null) {
      try {
        final cachedUser = UserModel.fromJson(jsonDecode(localUserInfo));
        debugPrint('👤 从本地缓存加载用户信息成功: ${cachedUser.name}');
        return cachedUser;
      } catch (e) {
        debugPrint('❌ 解析本地用户信息失败: $e');
        return UserModel.empty();
      }
    } else {
      debugPrint('❌ 本地缓存中没有用户信息');
      return UserModel.empty();
    }
  }

  /// 从本地存储加载用户信息和 JWT
  Future<UserModel> loadUser() async {
    debugPrint('🚀 开始加载用户状态');

    // 从本地存储加载用户信息
    final localUserInfo = await _secureStorage.read(
      key: _userInfoKey,
    ); // 用 secureStorage 读取
    if (localUserInfo != null) {
      try {
        _userInfo = UserModel.fromJson(jsonDecode(localUserInfo));
        debugPrint('👤 已加载本地用户信息: ${_userInfo.name}');
      } catch (e) {
        debugPrint('❌ 解析本地用户信息失败: $e');
        _userInfo = UserModel.empty();
      }
    } else {
      _userInfo = UserModel.empty();
    }

    // 通过 API 获取最新的用户信息，并覆盖本地用户信息
    final updatedUserInfo = await getUser();
    if (updatedUserInfo != null) {
      _userInfo = updatedUserInfo;
      await saveUser();
      debugPrint('🔄 用户信息已更新');
    } else {
      debugPrint('❌ 获取用户信息失败');
    }
    return _userInfo;
  }

  /// 初始化用户状态
  Future<bool> initUser() async {
    debugPrint('🚀 开始初始化用户状态');
    final loadedUser = await loadUser();
    if (loadedUser != UserModel.empty()) {
      debugPrint('🎉 用户信息已加载');
      return true;
    } else {
      debugPrint('❌ 用户信息加载失败');
      return false;
    }
  }

  UserModel get userInfo => _userInfo;
  String get jwt => _jwt;

  /// 检查 JWT 是否过期
  Future<bool> getJwtExpiration() async {
    debugPrint('🕰️ 开始检查 JWT 过期状态');
    try {
      // 使用新的配置系统获取用户偏好
      final allConfigs = await _configService.getAllConfigs();
      final autoRenewalEnabled = allConfigs.appConfig.autoRenewalCheckInService;

      debugPrint('🔍 JWT 过期检查配置: $autoRenewalEnabled');
      final res = await _apiService.getJwtIsExpired(autoRenewalEnabled);
      final isExpired = !res['success'];
      debugPrint('🔑 JWT 过期状态: ${isExpired ? '已过期' : '有效'}');
      return isExpired;
    } catch (error) {
      debugPrint('❌ JWT 过期检查错误: $error');
      return true;
    }
  }

  /// 解析 JWT 并检查其有效性
  bool isJwtValid(String jwt) {
    try {
      // JWT 格式: DoorKey=token
      if (jwt.isEmpty) return false;

      // 移除 DoorKey= 前缀
      final token = jwt.startsWith('DoorKey=') ? jwt.substring(8) : jwt;

      // 简单的 JWT 格式验证
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // 解码 payload
      final payload = parts[1];
      final normalizedPayload = _base64UrlNormalize(payload);
      final payloadMap = json.decode(
        utf8.decode(base64Url.decode(normalizedPayload)),
      );

      // 检查过期时间
      final exp = payloadMap['exp'];
      if (exp == null) return false;

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final isNotExpired = expirationTime.isAfter(DateTime.now());

      debugPrint('🕰️ JWT 解析: 过期时间 $expirationTime, 是否有效: $isNotExpired');
      return isNotExpired;
    } catch (e) {
      debugPrint('❌ JWT 解析错误: $e');
      return false;
    }
  }

  /// 规范化 Base64Url 编码
  String _base64UrlNormalize(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
    }
    return output;
  }

  /// 更新用户信息并保存到本地存储
  void updateUserInfo(UserModel user) async {
    debugPrint('🔄 更新用户信息: ${user.name}');
    _userInfo = user;
    await saveUser();
  }

  /// 保存用户信息和 JWT 到本地存储
  Future<void> saveUser() async {
    debugPrint('💾 开始保存用户信息和 JWT 到本地存储');
    await _secureStorage.write(
      key: _userInfoKey,
      value: jsonEncode(_userInfo.toJson()),
    ); // 使用 secureStorage 保存用户信息
    await _secureStorage.write(
      key: jwtKey,
      value: _jwt,
    ); // 使用 secureStorage 保存 JWT
    debugPrint('👤 已保存用户信息: ${_userInfo.name}');
    debugPrint('🔐 已保存 JWT: ${_jwt.isNotEmpty ? '有效' : '无效'}');
  }

  /// 获取用户信息
  Future<UserModel?> getUser() async {
    debugPrint('👤 开始获取用户信息');
    try {
      final res = await _apiService.getHome();
      if (res['success']) {
        // 检查data是否为null
        if (res['data'] == null) {
          debugPrint('❌ API返回成功但数据为null');
          return null;
        }
        final newUserInfo = UserModel.fromJson(res['data']);
        debugPrint('🔍 获取用户信息成功: ${newUserInfo.name}');

        // 微信授权逻辑
        if (newUserInfo.openId.isEmpty) {
          debugPrint('🔒 未找到 OpenID，开始微信授权');
          try {
            final code = await _apiService.requestWeixinCode();
            debugPrint('🌐 获取微信授权码: $code');
            final updateRes = await _apiService.updateOpenId(code);
            if (updateRes['success']) {
              newUserInfo.openId = updateRes['data']['openId'];
              debugPrint('🎉 微信授权成功，OpenID: ${newUserInfo.openId}');
            } else {
              debugPrint('❌ 微信授权失败');
            }
          } catch (e) {
            debugPrint('❌ 微信授权异常: $e');
          }
        }

        _userInfo = newUserInfo;
        await saveUser();
        return _userInfo;
      }
      debugPrint('❌ 获取用户信息失败');
      return null;
    } catch (e) {
      debugPrint('❌ 获取用户信息异常: $e');
      return null;
    }
  }

  /// 登录
  Future<bool> login(String account, String password) async {
    debugPrint('🔐 开始登录: account=$account');
    try {
      final res = await _apiService.swuLogin({
        'account': account,
        'password': password,
      });
      if (res['success']) {
        debugPrint('🎉 登录成功');
        // 提取 JWT
        final headers = res['__headers'] as Map<String, String>? ?? {};
        final cookie = headers['set-cookie'] ?? headers['Set-Cookie'] ?? '';
        debugPrint('🍪 Cookie: $cookie');
        final jwtPart = cookie
            .split(';')
            .firstWhere(
              (row) => row.trim().startsWith('DoorKey='),
              orElse: () => '',
            );

        if (jwtPart.isNotEmpty) {
          _jwt = jwtPart.trim();
          debugPrint('🔑 JWT 提取成功: ${_jwt.substring(0, 20)}...');
          await saveUser();

          // 清空上一个账号的课表缓存数据
          debugPrint('🗑️ 清空旧账号的缓存数据');
          final prefs = await SharedPreferences.getInstance();
          final keys = prefs.getKeys();
          for (final key in keys) {
            if (key.startsWith('classTable-') ||
                key.startsWith('grade') ||
                key.startsWith('custom') ||
                key.contains('course')) {
              await prefs.remove(key);
              debugPrint('🗑️ 删除缓存: $key');
            }
          }

          // 获取用户信息
          await getUser();
          // 获取配置
          final configRes = await _apiService.getConfig();
          if (configRes['code'] == 200 &&
              configRes['data']?['settings'] != null) {
            final serverSettings = Map<String, dynamic>.from(
              configRes['data']['settings'],
            );
            // 确保autoSync为false（如旧系统逻辑）
            serverSettings['autoSync'] = false;

            debugPrint('⚙️ 更新配置: $serverSettings');

            // 使用新配置系统保存配置
            final result = await _configService.initialize(
              apiData: serverSettings,
            );
            if (result.success) {
              debugPrint('✅ 配置更新成功');
            } else {
              debugPrint('⚠️ 配置更新失败: ${result.message}');
            }
          }
          return true;
        }
      }
      debugPrint('❌ 登录失败');
      return false;
    } catch (e) {
      debugPrint('❌ 登录异常: $e');
      return false;
    }
  }

  /// 注销
  Future<void> logout() async {
    debugPrint('🚪 开始注销');
    // 清空用户信息和 JWT
    _userInfo = UserModel.empty();
    _jwt = '';
    await saveUser();
    final index = await _secureStorage.read(key: 'index');
    final weather = await _secureStorage.read(key: 'weather');
    debugPrint('🗑️ 清空本地存储');
    await _secureStorage.deleteAll(); // 删除所有 secureStorage 数据
    if (index != null) {
      await _secureStorage.write(key: 'index', value: index);
      debugPrint('💾 恢复 index: $index');
    }
    if (weather != null) {
      await _secureStorage.write(key: 'weather', value: weather);
      debugPrint('💾 恢复 weather: $weather');
    }

    // 清空SharedPreferences中的课表缓存数据
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    debugPrint('🔍 当前SharedPreferences中的所有键: $keys');
    for (final key in keys) {
      // 匹配成绩缓存键（如果有）
      // 匹配自定义课程缓存键（如果有）
      if (key.startsWith('classTable-') ||
          key.startsWith('grade') ||
          key.startsWith('custom') ||
          key.contains('course') ||
          key.contains('class')) {
        await prefs.remove(key);
        debugPrint('🗑️ 删除缓存: $key');
      }
    }

    // 清空桌面小组件数据
    try {
      await WidgetService.clearClassTableWidget();
      debugPrint('🔄 桌面小组件数据已清空');
    } catch (e) {
      debugPrint('⚠️ 清空桌面小组件失败: $e');
    }

    // 重置配置到默认状态
    final result = await _configService.resetAllConfigs();
    if (result.success) {
      debugPrint('🔄 配置已重置');
    } else {
      debugPrint('⚠️ 配置重置失败: ${result.message}');
    }
  }

  /// 检查登录状态
  Future<bool> check() async {
    debugPrint('🕵️ 检查登录状态');
    _jwt = await _secureStorage.read(key: jwtKey) ?? '';

    // 本地 JWT 检查
    if (_jwt.isEmpty) {
      debugPrint('🚫 没有 JWT');
      return false;
    }
    debugPrint('本地 JWT: $_jwt');

    // 本地验证 JWT
    final isLocallyValid = isJwtValid(_jwt);
    if (isLocallyValid) {
      debugPrint('✅ 本地 JWT 验证成功');
      return true;
    }

    // 如果本地验证失败，尝试远程验证
    debugPrint('❌ 本地 JWT 验证失败，尝试远程验证');
    final isRemotelyValid = !await getJwtExpiration();

    debugPrint('✅ 登录状态: ${isRemotelyValid ? '已登录' : '未登录'}');
    return isRemotelyValid;
  }
}
