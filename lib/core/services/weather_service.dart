// lib/core/services/weather_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../models/weather_model.dart';
import 'api_service.dart';

/// 天气服务
/// 负责从API获取天气数据并管理本地缓存
class WeatherService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;

  static const String _weatherCacheKey = 'weather_cache';
  static const String _weatherUpdateTimeKey = 'weather_update_time';
  static const Duration _cacheExpiration = Duration(hours: 2); // 2小时过期

  WeatherService(this._apiService, this._secureStorage);

  /// 获取天气数据（优先从缓存获取，如果过期则重新获取）
  Future<WeatherDaily?> getWeather({bool forceRefresh = false}) async {
    try {
      // 检查缓存是否存在且未过期
      if (!forceRefresh) {
        final cachedWeather = await _getCachedWeather();
        if (cachedWeather != null) {
          debugPrint('🌤️ 从缓存获取天气数据');
          return cachedWeather;
        }
      }

      // 从API获取新数据
      debugPrint('🌤️ 从API获取天气数据');
      final response = await _apiService.getWeather();

      if (response['status'] == 'ok') {
        final weatherModel = WeatherModel.fromJson(response);

        // 更新日期信息
        final dailyWithDate = WeatherDaily(
          date: DateTime.now().toLocal().toString().split(' ')[0],
          temperature: weatherModel.daily.temperature,
          skycon08h20h: weatherModel.daily.skycon08h20h,
          skycon20h32h: weatherModel.daily.skycon20h32h,
        );

        // 缓存数据
        await _cacheWeather(dailyWithDate);

        return dailyWithDate;
      } else {
        debugPrint('❌ 天气API返回错误状态: ${response['status']}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 获取天气数据失败: $e');

      // 如果API请求失败，尝试返回缓存数据（即使已过期）
      final cachedWeather = await _getCachedWeather(ignoreExpiration: true);
      if (cachedWeather != null) {
        debugPrint('⚠️ API失败，使用过期缓存数据');
        return cachedWeather;
      }

      return null;
    }
  }

  /// 从缓存获取天气数据
  Future<WeatherDaily?> _getCachedWeather({
    bool ignoreExpiration = false,
  }) async {
    try {
      final cachedData = await _secureStorage.read(key: _weatherCacheKey);
      final updateTimeStr = await _secureStorage.read(
        key: _weatherUpdateTimeKey,
      );

      if (cachedData == null || updateTimeStr == null) {
        return null;
      }

      // 检查是否过期
      if (!ignoreExpiration) {
        final updateTime = DateTime.parse(updateTimeStr);
        final now = DateTime.now();
        if (now.difference(updateTime) > _cacheExpiration) {
          debugPrint('🌤️ 天气缓存已过期');
          return null;
        }
      }

      final weatherJson = jsonDecode(cachedData) as Map<String, dynamic>;
      return WeatherDaily.fromJson(weatherJson);
    } catch (e) {
      debugPrint('❌ 读取天气缓存失败: $e');
      return null;
    }
  }

  /// 缓存天气数据
  Future<void> _cacheWeather(WeatherDaily weather) async {
    try {
      final weatherJson = jsonEncode(weather.toJson());
      final updateTime = DateTime.now().toIso8601String();

      await _secureStorage.write(key: _weatherCacheKey, value: weatherJson);
      await _secureStorage.write(key: _weatherUpdateTimeKey, value: updateTime);

      debugPrint('💾 天气数据已缓存');
    } catch (e) {
      debugPrint('❌ 缓存天气数据失败: $e');
    }
  }

  /// 格式化天气显示文本
  String formatWeatherText(WeatherDaily weather) {
    if (weather.temperature.isEmpty || weather.skycon08h20h.isEmpty) {
      return '';
    }

    // 温度范围
    final temp = weather.temperature[0];
    final temperature = '${temp.min.round()} - ${temp.max.round()}℃ ';

    // 天气状况
    final skycon08h20h = weather.skycon08h20h[0].value;
    final skycon20h32h = weather.skycon20h32h.isNotEmpty
        ? weather.skycon20h32h[0].value
        : skycon08h20h;

    final dayWeather = WeatherNames.getName(skycon08h20h);
    final nightWeather = WeatherNames.getName(skycon20h32h);

    final weatherText = dayWeather == nightWeather
        ? dayWeather
        : '$dayWeather转$nightWeather';

    return temperature + weatherText;
  }

  /// 清除天气缓存
  Future<void> clearCache() async {
    try {
      await _secureStorage.delete(key: _weatherCacheKey);
      await _secureStorage.delete(key: _weatherUpdateTimeKey);
      debugPrint('🗑️ 天气缓存已清除');
    } catch (e) {
      debugPrint('❌ 清除天气缓存失败: $e');
    }
  }
}
