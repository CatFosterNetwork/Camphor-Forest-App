// lib/core/providers/auth_provider.dart
import 'dart:async';

import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'core_providers.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool initialized;
  final String? errorMessage;
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.initialized = false,
  });
  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? initialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }

  @override
  String toString() {
    return 'AuthState(user: $user, isLoading: $isLoading, initialized: $initialized, errorMessage: $errorMessage)';
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final UserService _userService;

  AuthNotifier._internal(this._userService) : super(const AuthState());

  /// 异步工厂构造函数
  static Future<AuthNotifier> create(UserService userService) async {
    final notifier = AuthNotifier._internal(userService);
    await notifier._initialize();
    return notifier;
  }

  /// 异步初始化方法
  Future<void> _initialize() async {
    AppLogger.debug('🔐 开始初始化 AuthNotifier');
    state = state.copyWith(isLoading: true);

    try {
      await _userService.initialize();

      // 检查是否已经有登录状态
      final isLoggedIn = await _userService.check();
      if (isLoggedIn) {
        final user = await _userService.getUser();
        if (user != null) {
          state = state.copyWith(
            user: user,
            isLoading: false,
            initialized: true,
          );
          AppLogger.debug('🟢 用户已登录，状态已恢复: ${user.name}');
        } else {
          state = state.copyWith(isLoading: false, initialized: true);
          AppLogger.debug('🔴 用户信息获取失败');
        }
      } else {
        state = state.copyWith(isLoading: false, initialized: true);
        AppLogger.debug('🔐 用户未登录');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        initialized: true,
        errorMessage: '初始化失败：${e.toString()}',
      );
      AppLogger.debug('🔴 AuthNotifier 初始化失败: $e');
    }
  }

  Future<bool> login(String account, String password) async {
    AppLogger.debug('🔐 开始登录: account=$account');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      AppLogger.debug('🔐 调用 UserService 登录方法');
      final success = await _userService.login(account, password);
      AppLogger.debug('🔐 登录结果: $success');

      if (!success) {
        state = state.copyWith(isLoading: false, errorMessage: '登录失败，请检查账号和密码');
        AppLogger.debug('🔴 登录失败: ${state.errorMessage}');
        return false;
      }

      // 尝试获取用户信息
      try {
        AppLogger.debug('🔐 尝试获取用户信息');
        final u = await _userService.getUser();
        AppLogger.debug('🔐 获取用户信息结果: ${u?.name ?? "未获取到用户信息"}');

        if (u != null) {
          state = state.copyWith(user: u, isLoading: false, initialized: true);
          AppLogger.debug('🟢 登录成功，用户信息已更新: $state');
          return true;
        } else {
          state = state.copyWith(isLoading: false, errorMessage: '获取用户信息失败');
          AppLogger.debug('🔴 获取用户信息失败: ${state.errorMessage}');
          return false;
        }
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '获取用户信息异常：${e.toString()}',
        );
        AppLogger.debug('🔴 获取用户信息异常: ${state.errorMessage}');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登录异常：${e.toString()}',
      );
      AppLogger.debug('🔴 登录异常: ${state.errorMessage}');
      return false;
    }
  }

  Future<void> logout() async {
    AppLogger.debug('🔐 开始注销');
    await _userService.logout();
    state = const AuthState();
    AppLogger.debug('🔐 注销完成');
  }

  /// 刷新用户数据
  Future<void> refreshUser() async {
    AppLogger.debug('🔄 开始刷新用户数据');
    if (state.user == null) {
      AppLogger.debug('❌ 用户未登录，无法刷新');
      return;
    }

    try {
      final user = await _userService.getUser();
      if (user != null) {
        state = state.copyWith(user: user);
        AppLogger.debug('🟢 用户数据刷新成功: ${user.name}');
      } else {
        // API返回null时，尝试从本地缓存重新加载
        AppLogger.debug('⚠️ API返回null，尝试从本地缓存重新加载用户数据');
        final cachedUser = await _userService.loadUserFromCache();
        if (cachedUser != UserModel.empty()) {
          state = state.copyWith(user: cachedUser);
          AppLogger.debug('🔄 从本地缓存加载用户数据成功: ${cachedUser.name}');
        } else {
          AppLogger.debug('❌ 本地缓存也没有有效的用户数据');
        }
      }
    } catch (e) {
      AppLogger.debug('❌ 刷新用户数据异常: $e');
      // 异常时也尝试从本地缓存加载
      try {
        final cachedUser = await _userService.loadUserFromCache();
        if (cachedUser != UserModel.empty()) {
          state = state.copyWith(user: cachedUser);
          AppLogger.debug('🔄 异常恢复：从本地缓存加载用户数据成功: ${cachedUser.name}');
        }
      } catch (cacheError) {
        AppLogger.debug('❌ 从本地缓存加载也失败: $cacheError');
      }
    }
  }

  /// 直接更新用户信息（用于本地修改后立即更新状态）
  void updateUser(UserModel user) {
    AppLogger.debug('🔄 直接更新用户状态: ${user.name}');
    state = state.copyWith(user: user);
    // 同时保存到本地缓存
    _userService.updateUserInfo(user);
  }

  bool get isAuthenticated => state.user != null;

  /// 获取当前状态 - 供外部访问
  AuthState get currentState => state;
}

/// 异步认证通知器 - 使用 AsyncNotifier 实现自动状态传播
class AuthAsyncNotifier extends AsyncNotifier<AuthState> {
  late UserService _userService;

  @override
  Future<AuthState> build() async {
    AppLogger.debug('🔐 开始构建 AuthAsyncNotifier');

    // 获取 UserService
    _userService = await ref.watch(userServiceProvider.future);

    // 初始化用户状态
    return await _initialize();
  }

  /// 初始化认证状态
  Future<AuthState> _initialize() async {
    AppLogger.debug('🔐 开始初始化认证状态');

    try {
      await _userService.initialize();

      // 检查是否已经有登录状态
      final isLoggedIn = await _userService.check();
      if (isLoggedIn) {
        final user = await _userService.getUser();
        if (user != null) {
          AppLogger.debug('🟢 用户已登录，状态已恢复: ${user.name}');
          return AuthState(user: user, isLoading: false, initialized: true);
        } else {
          AppLogger.debug('🔴 用户信息获取失败');
          return const AuthState(isLoading: false, initialized: true);
        }
      } else {
        AppLogger.debug('🔐 用户未登录');
        return const AuthState(isLoading: false, initialized: true);
      }
    } catch (e) {
      AppLogger.debug('🔴 认证初始化失败: $e');
      return AuthState(
        isLoading: false,
        initialized: true,
        errorMessage: '初始化失败：${e.toString()}',
      );
    }
  }

  /// 登录
  Future<bool> login(String account, String password) async {
    AppLogger.debug('🔐 开始登录: account=$account');

    // 设置加载状态
    state = AsyncValue.data(
      state.value!.copyWith(isLoading: true, errorMessage: null),
    );

    try {
      AppLogger.debug('🔐 调用 UserService 登录方法');
      final success = await _userService.login(account, password);
      AppLogger.debug('🔐 登录结果: $success');

      if (!success) {
        state = AsyncValue.data(
          state.value!.copyWith(
            isLoading: false,
            errorMessage: '登录失败，请检查账号和密码',
          ),
        );
        AppLogger.debug('🔴 登录失败');
        return false;
      }

      // 尝试获取用户信息
      try {
        AppLogger.debug('🔐 尝试获取用户信息');
        final u = await _userService.getUser();
        AppLogger.debug('🔐 获取用户信息结果: ${u?.name ?? "未获取到用户信息"}');

        if (u != null) {
          state = AsyncValue.data(
            AuthState(user: u, isLoading: false, initialized: true),
          );
          AppLogger.debug('🟢 登录成功，用户信息已更新');
          return true;
        } else {
          state = AsyncValue.data(
            state.value!.copyWith(isLoading: false, errorMessage: '获取用户信息失败'),
          );
          AppLogger.debug('🔴 获取用户信息失败');
          return false;
        }
      } catch (e) {
        state = AsyncValue.data(
          state.value!.copyWith(
            isLoading: false,
            errorMessage: '获取用户信息异常：${e.toString()}',
          ),
        );
        AppLogger.debug('🔴 获取用户信息异常: $e');
        return false;
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          errorMessage: '登录异常：${e.toString()}',
        ),
      );
      AppLogger.debug('🔴 登录异常: $e');
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    AppLogger.debug('🔐 开始注销');
    await _userService.logout();
    state = const AsyncValue.data(AuthState());
    AppLogger.debug('🔐 注销完成');
  }

  /// 刷新用户数据
  Future<void> refreshUser() async {
    AppLogger.debug('🔄 开始刷新用户数据');

    final currentState = state.value;
    if (currentState?.user == null) {
      AppLogger.debug('❌ 用户未登录，无法刷新');
      return;
    }

    try {
      final user = await _userService.getUser();
      if (user != null) {
        state = AsyncValue.data(currentState!.copyWith(user: user));
        AppLogger.debug('🟢 用户数据刷新成功: ${user.name}');
      } else {
        // API返回null时，尝试从本地缓存重新加载
        AppLogger.debug('⚠️ API返回null，尝试从本地缓存重新加载用户数据');
        final cachedUser = await _userService.loadUserFromCache();
        if (cachedUser != UserModel.empty()) {
          state = AsyncValue.data(currentState!.copyWith(user: cachedUser));
          AppLogger.debug('🔄 从本地缓存加载用户数据成功: ${cachedUser.name}');
        } else {
          AppLogger.debug('❌ 本地缓存也没有有效的用户数据');
        }
      }
    } catch (e) {
      AppLogger.debug('❌ 刷新用户数据异常: $e');
      // 异常时也尝试从本地缓存加载
      try {
        final cachedUser = await _userService.loadUserFromCache();
        if (cachedUser != UserModel.empty()) {
          state = AsyncValue.data(currentState!.copyWith(user: cachedUser));
          AppLogger.debug('🔄 异常恢复：从本地缓存加载用户数据成功: ${cachedUser.name}');
        }
      } catch (cacheError) {
        AppLogger.debug('❌ 从本地缓存加载也失败: $cacheError');
      }
    }
  }

  /// 直接更新用户信息
  void updateUser(UserModel user) {
    AppLogger.debug('🔄 直接更新用户状态: ${user.name}');
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(user: user));
      // 同时保存到本地缓存
      _userService.updateUserInfo(user);
    }
  }
}

/// 异步认证状态Provider - 使用 AsyncNotifierProvider
final authAsyncNotifierProvider =
    AsyncNotifierProvider<AuthAsyncNotifier, AuthState>(() {
      return AuthAsyncNotifier();
    });

/// 便捷的认证状态获取Provider
final authProvider = Provider<AuthState>((ref) {
  final authAsync = ref.watch(authAsyncNotifierProvider);
  return authAsync.when(
    data: (state) => state,
    loading: () => const AuthState(isLoading: true),
    error: (error, _) =>
        AuthState(initialized: true, errorMessage: error.toString()),
  );
});

/// 认证状态Provider - 向后兼容
final authStateProvider = Provider<AsyncValue<AuthState>>((ref) {
  return ref.watch(authAsyncNotifierProvider);
});

/// 认证状态检查Helper
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user != null;
});

/// 当前用户Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Auth操作扩展 - 提供便捷的操作方法
extension AuthNotifierExtensions on WidgetRef {
  /// 执行登录操作
  Future<bool> login(String account, String password) async {
    return read(authAsyncNotifierProvider.notifier).login(account, password);
  }

  /// 执行注销操作
  Future<void> logout() async {
    return read(authAsyncNotifierProvider.notifier).logout();
  }

  /// 刷新用户数据
  Future<void> refreshUser() async {
    return read(authAsyncNotifierProvider.notifier).refreshUser();
  }

  /// 直接更新用户信息
  void updateUser(UserModel user) {
    read(authAsyncNotifierProvider.notifier).updateUser(user);
  }

  /// 获取当前认证状态
  AuthState getAuthState() {
    return read(authProvider);
  }

  /// 检查是否已认证
  bool isAuthenticated() {
    return read(isAuthenticatedProvider);
  }

  /// 获取当前用户
  UserModel? getCurrentUser() {
    return read(currentUserProvider);
  }
}
