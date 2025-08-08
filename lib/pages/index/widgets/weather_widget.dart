// lib/pages/index/widgets/weather_widget.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/weather_provider.dart';
import '../../../core/models/weather_model.dart';

/// 天气组件 - 显示当前天气信息
class WeatherWidget extends ConsumerStatefulWidget {
  final bool blur;
  final bool darkMode;

  const WeatherWidget({
    super.key,
    required this.blur,
    required this.darkMode,
  });

  @override
  ConsumerState<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends ConsumerState<WeatherWidget> {
  @override
  void initState() {
    super.initState();
    // 确保天气数据可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.ensureWeatherData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    
    // 如果正在加载且没有缓存数据，显示加载指示器
    if (weatherState.isLoading && weatherState.weather == null) {
      return _buildLoadingWidget();
    }
    
    // 如果没有天气数据，不显示组件
    if (weatherState.weather == null) {
      return const SizedBox.shrink();
    }

    final weather = weatherState.weather!;
    final temperature = weather.temperature.isNotEmpty 
        ? weather.temperature[0] 
        : null;
    final weatherCondition = weather.skycon08h20h.isNotEmpty 
        ? WeatherNames.getName(weather.skycon08h20h[0].value)
        : '未知';

    if (temperature == null) {
      return const SizedBox.shrink();
    }

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.darkMode 
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        border: Border.all(
          color: widget.darkMode 
              ? Colors.white.withAlpha(26)
              : Colors.black.withAlpha(13),
          width: 0.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getWeatherIcon(weatherCondition),
            color: widget.darkMode ? Colors.white70 : Colors.black87,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${temperature.avg.round()}°C',
            style: TextStyle(
              color: widget.darkMode ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            weatherCondition,
            style: TextStyle(
              color: widget.darkMode ? Colors.white60 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    // 应用模糊效果 - 模糊背景而不是内容
    if (widget.blur) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: widget.darkMode 
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(20),
                      border: widget.darkMode ? Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ) : null,
            ),
            child: child,
          ),
        ),
      );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      );
    }

    return child;
  }

  /// 构建加载中的组件
  Widget _buildLoadingWidget() {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.darkMode 
            ? Colors.black.withAlpha(76) 
            : Colors.white.withAlpha(76),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.darkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '加载中...',
            style: TextStyle(
              color: widget.darkMode ? Colors.white70 : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    // 应用模糊效果 - 模糊背景而不是内容
    if (widget.blur) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: widget.darkMode 
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(20),
                      border: widget.darkMode ? Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ) : null,
            ),
            child: child,
          ),
        ),
      );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      );
    }

    return child;
  }

  /// 根据天气状况获取图标
  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case '晴':
        return Icons.wb_sunny;
      case '多云':
        return Icons.wb_cloudy;
      case '阴':
        return Icons.cloud;
      case '小雨':
      case '中雨':
      case '大雨':
      case '暴雨':
        return Icons.grain;
      case '小雪':
      case '中雪':
      case '大雪':
      case '暴雪':
        return Icons.ac_unit;
      case '雾':
      case '轻度雾霾':
      case '中度雾霾':
      case '重度雾霾':
        return Icons.blur_on;
      case '浮尘':
      case '沙尘':
        return Icons.blur_circular;
      case '大风':
        return Icons.air;
      default:
        return Icons.wb_sunny;
    }
  }
}