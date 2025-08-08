// lib/core/models/weather_model.dart

/// 天气数据模型，对应彩云天气API返回的数据结构
class WeatherModel {
  final String status;
  final WeatherDaily daily;

  WeatherModel({
    required this.status,
    required this.daily,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      status: json['status'] as String,
      daily: WeatherDaily.fromJson(json['result']['daily'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'result': {
        'daily': daily.toJson(),
      },
    };
  }
}

/// 天气每日数据
class WeatherDaily {
  final String? date;
  final List<TemperatureInfo> temperature;
  final List<SkyconInfo> skycon08h20h;
  final List<SkyconInfo> skycon20h32h;

  WeatherDaily({
    this.date,
    required this.temperature,
    required this.skycon08h20h,
    required this.skycon20h32h,
  });

  factory WeatherDaily.fromJson(Map<String, dynamic> json) {
    return WeatherDaily(
      date: json['date'] as String?,
      temperature: (json['temperature'] as List<dynamic>)
          .map((e) => TemperatureInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      skycon08h20h: (json['skycon_08h_20h'] as List<dynamic>)
          .map((e) => SkyconInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      skycon20h32h: (json['skycon_20h_32h'] as List<dynamic>)
          .map((e) => SkyconInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'temperature': temperature.map((e) => e.toJson()).toList(),
      'skycon_08h_20h': skycon08h20h.map((e) => e.toJson()).toList(),
      'skycon_20h_32h': skycon20h32h.map((e) => e.toJson()).toList(),
    };
  }
}

/// 温度信息
class TemperatureInfo {
  final String date;
  final double max;
  final double min;
  final double avg;

  TemperatureInfo({
    required this.date,
    required this.max,
    required this.min,
    required this.avg,
  });

  factory TemperatureInfo.fromJson(Map<String, dynamic> json) {
    return TemperatureInfo(
      date: json['date'] as String,
      max: (json['max'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      avg: (json['avg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'max': max,
      'min': min,
      'avg': avg,
    };
  }
}

/// 天气状况信息
class SkyconInfo {
  final String date;
  final String value;

  SkyconInfo({
    required this.date,
    required this.value,
  });

  factory SkyconInfo.fromJson(Map<String, dynamic> json) {
    return SkyconInfo(
      date: json['date'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'value': value,
    };
  }
}

class WeatherNames {
  static const Map<String, String> names = {
    'CLEAR_DAY': '晴',
    'CLEAR_NIGHT': '晴',
    'PARTLY_CLOUDY_DAY': '多云',
    'PARTLY_CLOUDY_NIGHT': '多云',
    'CLOUDY': '阴',
    'LIGHT_HAZE': '轻度雾霾',
    'MODERATE_HAZE': '中度雾霾',
    'HEAVY_HAZE': '重度雾霾',
    'LIGHT_RAIN': '小雨',
    'MODERATE_RAIN': '中雨',
    'HEAVY_RAIN': '大雨',
    'STORM_RAIN': '暴雨',
    'FOG': '雾',
    'LIGHT_SNOW': '小雪',
    'MODERATE_SNOW': '中雪',
    'HEAVY_SNOW': '大雪',
    'STORM_SNOW': '暴雪',
    'DUST': '浮尘',
    'SAND': '沙尘',
    'WIND': '大风',
  };

  static String getName(String code) {
    return names[code] ?? '未知';
  }
}