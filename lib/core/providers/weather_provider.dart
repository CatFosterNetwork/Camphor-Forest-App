// lib/core/providers/weather_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'core_providers.dart';

/// 天气状态
class WeatherState {
  final WeatherDaily? weather;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  WeatherState copyWith({
    WeatherDaily? weather,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 获取格式化的天气文本
  String getFormattedText(WidgetRef ref) {
    if (weather == null) return '';
    return ref.read(weatherServiceProvider).formatWeatherText(weather!);
  }

  /// 获取当前温度
  String get currentTemperature {
    if (weather?.temperature.isEmpty ?? true) return '';
    final temp = weather!.temperature[0];
    return '${temp.avg.round()}℃';
  }

  /// 获取天气状况
  String get weatherCondition {
    if (weather?.skycon08h20h.isEmpty ?? true) return '';
    final skycon = weather!.skycon08h20h[0].value;
    return WeatherNames.getName(skycon);
  }

  /// 是否有有效的天气数据
  bool get hasValidData =>
      weather != null && !isLoading && errorMessage == null;
}

/// 天气状态管理器
class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _weatherService;

  WeatherNotifier(this._weatherService) : super(const WeatherState());

  /// 获取天气数据
  Future<void> fetchWeather({bool forceRefresh = false}) async {
    if (state.isLoading) return; // 防止重复请求

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final weather = await _weatherService.getWeather(
        forceRefresh: forceRefresh,
      );

      if (weather != null) {
        state = state.copyWith(
          weather: weather,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        AppLogger.debug('✅ 天气数据更新成功');
      } else {
        state = state.copyWith(isLoading: false, errorMessage: '无法获取天气数据');
        AppLogger.debug('❌ 天气数据为空');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '获取天气数据失败: $e');
      AppLogger.debug('❌ 天气数据获取异常: $e');
    }
  }

  /// 刷新天气数据
  Future<void> refreshWeather() async {
    await fetchWeather(forceRefresh: true);
  }

  /// 清除天气数据
  Future<void> clearWeather() async {
    await _weatherService.clearCache();
    state = const WeatherState();
  }
}

/// 天气服务Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return WeatherService(apiService, secureStorage);
});

/// 天气状态Provider
final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((
  ref,
) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});

/// 便捷的天气数据Provider
final currentWeatherProvider = Provider<WeatherDaily?>((ref) {
  return ref.watch(weatherProvider).weather;
});

/// 天气加载状态Provider
final weatherLoadingProvider = Provider<bool>((ref) {
  return ref.watch(weatherProvider).isLoading;
});

/// 天气错误Provider
final weatherErrorProvider = Provider<String?>((ref) {
  return ref.watch(weatherProvider).errorMessage;
});

/// WidgetRef扩展，提供便捷的天气操作方法
extension WeatherProviderExtensions on WidgetRef {
  /// 获取天气数据（如果没有则自动获取）
  Future<void> ensureWeatherData() async {
    final weatherState = read(weatherProvider);
    if (weatherState.weather == null && !weatherState.isLoading) {
      await read(weatherProvider.notifier).fetchWeather();
    }
  }

  /// 刷新天气数据
  Future<void> refreshWeather() async {
    await read(weatherProvider.notifier).refreshWeather();
  }

  /// 获取天气显示文本
  String getWeatherText() {
    final weather = read(currentWeatherProvider);
    if (weather == null) return '';
    return read(weatherServiceProvider).formatWeatherText(weather);
  }

  /// 获取当前温度
  String getCurrentTemperature() {
    return read(weatherProvider).currentTemperature;
  }

  /// 获取天气状况
  String getWeatherCondition() {
    return read(weatherProvider).weatherCondition;
  }
}
