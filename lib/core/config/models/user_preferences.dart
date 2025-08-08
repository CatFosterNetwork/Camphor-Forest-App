// lib/core/config/models/user_preferences.dart

/// 用户偏好配置模型
/// 管理用户个人偏好、缓存数据等非核心配置
class UserPreferences {
  /// 语言设置
  final String language;
  
  /// 是否启用通知
  final bool enableNotifications;
  
  /// 是否启用震动反馈
  final bool enableVibration;
  
  /// 是否启用声音反馈
  final bool enableSound;
  
  /// 缓存大小限制（MB）
  final int cacheLimit;
  
  /// 是否启用数据保护模式
  final bool enableDataSaver;
  
  /// 首次启动标记
  final bool isFirstLaunch;
  
  /// 上次同步时间
  final DateTime? lastSyncTime;
  
  /// 用户自定义数据缓存
  final Map<String, dynamic> customData;

  const UserPreferences({
    this.language = 'zh-CN',
    this.enableNotifications = true,
    this.enableVibration = true,
    this.enableSound = true,
    this.cacheLimit = 100, // 100MB
    this.enableDataSaver = false,
    this.isFirstLaunch = true,
    this.lastSyncTime,
    this.customData = const {},
  });

  /// 从JSON创建UserPreferences
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] ?? 'zh-CN',
      enableNotifications: json['enableNotifications'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      enableSound: json['enableSound'] ?? true,
      cacheLimit: json['cacheLimit'] ?? 100,
      enableDataSaver: json['enableDataSaver'] ?? false,
      isFirstLaunch: json['isFirstLaunch'] ?? true,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncTime'])
          : null,
      customData: Map<String, dynamic>.from(json['customData'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'enableNotifications': enableNotifications,
      'enableVibration': enableVibration,
      'enableSound': enableSound,
      'cacheLimit': cacheLimit,
      'enableDataSaver': enableDataSaver,
      'isFirstLaunch': isFirstLaunch,
      'lastSyncTime': lastSyncTime?.millisecondsSinceEpoch,
      'customData': customData,
    };
  }

  /// 复制并修改配置
  UserPreferences copyWith({
    String? language,
    bool? enableNotifications,
    bool? enableVibration,
    bool? enableSound,
    int? cacheLimit,
    bool? enableDataSaver,
    bool? isFirstLaunch,
    DateTime? lastSyncTime,
    Map<String, dynamic>? customData,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableVibration: enableVibration ?? this.enableVibration,
      enableSound: enableSound ?? this.enableSound,
      cacheLimit: cacheLimit ?? this.cacheLimit,
      enableDataSaver: enableDataSaver ?? this.enableDataSaver,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      customData: customData ?? this.customData,
    );
  }

  /// 设置自定义数据
  UserPreferences setCustomData(String key, dynamic value) {
    final newCustomData = Map<String, dynamic>.from(customData);
    newCustomData[key] = value;
    return copyWith(customData: newCustomData);
  }

  /// 获取自定义数据
  T? getCustomData<T>(String key) {
    final value = customData[key];
    return value is T ? value : null;
  }

  /// 移除自定义数据
  UserPreferences removeCustomData(String key) {
    final newCustomData = Map<String, dynamic>.from(customData);
    newCustomData.remove(key);
    return copyWith(customData: newCustomData);
  }

  /// 标记为已同步
  UserPreferences markSynced() {
    return copyWith(lastSyncTime: DateTime.now());
  }

  /// 标记为非首次启动
  UserPreferences markNotFirstLaunch() {
    return copyWith(isFirstLaunch: false);
  }

  /// 检查是否需要同步（超过1小时）
  bool get needsSync {
    if (lastSyncTime == null) return true;
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);
    return diff.inHours > 1;
  }

  /// 检查缓存是否接近限制
  bool isCacheNearLimit(int currentCacheSizeMB) {
    return currentCacheSizeMB >= (cacheLimit * 0.8); // 80%阈值
  }

  /// 默认配置
  static const UserPreferences defaultConfig = UserPreferences();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          enableNotifications == other.enableNotifications &&
          enableVibration == other.enableVibration &&
          enableSound == other.enableSound &&
          cacheLimit == other.cacheLimit &&
          enableDataSaver == other.enableDataSaver &&
          isFirstLaunch == other.isFirstLaunch &&
          lastSyncTime == other.lastSyncTime &&
          _mapEquals(customData, other.customData);

  @override
  int get hashCode =>
      language.hashCode ^
      enableNotifications.hashCode ^
      enableVibration.hashCode ^
      enableSound.hashCode ^
      cacheLimit.hashCode ^
      enableDataSaver.hashCode ^
      isFirstLaunch.hashCode ^
      lastSyncTime.hashCode ^
      customData.hashCode;

  /// Map相等性检查
  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'UserPreferences{language: $language, notifications: $enableNotifications, firstLaunch: $isFirstLaunch, customData: ${customData.length} items}';
  }
}