// lib/core/config/models/app_config.dart

/// 应用功能配置模型
/// 管理UI显示开关和基础应用设置
class AppConfig {
  // ===== 首页显示设置 =====
  final bool showFinishedTodo;
  final bool showTodo;
  final bool showExpense;
  final bool showClassroom;
  final bool showExams;
  final bool showGrades;
  final bool showIndexServices;

  // ===== 森林功能设置 =====
  final bool showFleaMarket;
  final bool showCampusRecruitment;
  final bool showSchoolNavigation;
  final bool showLibrary;
  final bool showBBS;
  final bool showAds;
  final bool showLifeService;
  final bool showFeedback;

  // ===== 应用基础设置 =====
  final bool autoSync;
  final bool autoRenewalCheckInService;

  const AppConfig({
    // 首页显示设置 - 默认全部显示
    this.showFinishedTodo = true,
    this.showTodo = true,
    this.showExpense = true,
    this.showClassroom = true,
    this.showExams = true,
    this.showGrades = true,
    this.showIndexServices = true,
    
    // 森林功能设置 - 默认显示核心功能
    this.showFleaMarket = false,
    this.showCampusRecruitment = false,
    this.showSchoolNavigation = true,
    this.showLibrary = false,
    this.showBBS = true,
    this.showAds = false,
    this.showLifeService = true,
    this.showFeedback = true,
    
    // 应用基础设置
    this.autoSync = false,
    this.autoRenewalCheckInService = false,
  });

  /// 从JSON创建AppConfig
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      // 首页显示设置
      showFinishedTodo: json['index-showFinishedTodo'] ?? true,
      showTodo: json['index-showTodo'] ?? true,
      showExpense: json['index-showExpense'] ?? true,
      showClassroom: json['index-showClassroom'] ?? true,
      showExams: json['index-showExams'] ?? true,
      showGrades: json['index-showGrades'] ?? true,
      showIndexServices: json['index-showIndexServices'] ?? true,
      
      // 森林功能设置
      showFleaMarket: json['forest-showFleaMarket'] ?? false,
      showCampusRecruitment: json['forest-showCampusRecruitment'] ?? false,
      showSchoolNavigation: json['forest-showSchoolNavigation'] ?? true,
      showLibrary: json['forest-showLibrary'] ?? false,
      showBBS: json['forest-showBBS'] ?? true,
      showAds: json['forest-showAds'] ?? false,
      showLifeService: json['forest-showLifeService'] ?? true,
      showFeedback: json['forest-showFeedback'] ?? true,
      
      // 应用基础设置
      autoSync: json['autoSync'] ?? false,
      autoRenewalCheckInService: json['autoRenewalCheckInService'] ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      // 首页显示设置
      'index-showFinishedTodo': showFinishedTodo,
      'index-showTodo': showTodo,
      'index-showExpense': showExpense,
      'index-showClassroom': showClassroom,
      'index-showExams': showExams,
      'index-showGrades': showGrades,
      'index-showIndexServices': showIndexServices,
      
      // 森林功能设置
      'forest-showFleaMarket': showFleaMarket,
      'forest-showCampusRecruitment': showCampusRecruitment,
      'forest-showSchoolNavigation': showSchoolNavigation,
      'forest-showLibrary': showLibrary,
      'forest-showBBS': showBBS,
      'forest-showAds': showAds,
      'forest-showLifeService': showLifeService,
      'forest-showFeedback': showFeedback,
      
      // 应用基础设置
      'autoSync': autoSync,
      'autoRenewalCheckInService': autoRenewalCheckInService,
    };
  }

  /// 复制并修改配置
  AppConfig copyWith({
    // 首页显示设置
    bool? showFinishedTodo,
    bool? showTodo,
    bool? showExpense,
    bool? showClassroom,
    bool? showExams,
    bool? showGrades,
    bool? showIndexServices,
    
    // 森林功能设置
    bool? showFleaMarket,
    bool? showCampusRecruitment,
    bool? showSchoolNavigation,
    bool? showLibrary,
    bool? showBBS,
    bool? showAds,
    bool? showLifeService,
    bool? showFeedback,
    
    // 应用基础设置
    bool? autoSync,
    bool? autoRenewalCheckInService,
  }) {
    return AppConfig(
      // 首页显示设置
      showFinishedTodo: showFinishedTodo ?? this.showFinishedTodo,
      showTodo: showTodo ?? this.showTodo,
      showExpense: showExpense ?? this.showExpense,
      showClassroom: showClassroom ?? this.showClassroom,
      showExams: showExams ?? this.showExams,
      showGrades: showGrades ?? this.showGrades,
      showIndexServices: showIndexServices ?? this.showIndexServices,
      
      // 森林功能设置
      showFleaMarket: showFleaMarket ?? this.showFleaMarket,
      showCampusRecruitment: showCampusRecruitment ?? this.showCampusRecruitment,
      showSchoolNavigation: showSchoolNavigation ?? this.showSchoolNavigation,
      showLibrary: showLibrary ?? this.showLibrary,
      showBBS: showBBS ?? this.showBBS,
      showAds: showAds ?? this.showAds,
      showLifeService: showLifeService ?? this.showLifeService,
      showFeedback: showFeedback ?? this.showFeedback,
      
      // 应用基础设置
      autoSync: autoSync ?? this.autoSync,
      autoRenewalCheckInService: autoRenewalCheckInService ?? this.autoRenewalCheckInService,
    );
  }

  /// 默认配置
  static const AppConfig defaultConfig = AppConfig();

  // ===== 便利方法 =====
  
  /// 获取首页显示设置的Map
  Map<String, bool> get indexDisplaySettings => {
    'index-showFinishedTodo': showFinishedTodo,
    'index-showTodo': showTodo,
    'index-showExpense': showExpense,
    'index-showClassroom': showClassroom,
    'index-showExams': showExams,
    'index-showGrades': showGrades,
    'index-showIndexServices': showIndexServices,
  };

  /// 获取森林功能设置的Map
  Map<String, bool> get forestFeatureSettings => {
    'forest-showFleaMarket': showFleaMarket,
    'forest-showCampusRecruitment': showCampusRecruitment,
    'forest-showSchoolNavigation': showSchoolNavigation,
    'forest-showLibrary': showLibrary,
    'forest-showBBS': showBBS,
    'forest-showAds': showAds,
    'forest-showLifeService': showLifeService,
    'forest-showFeedback': showFeedback,
  };

  /// 检查是否有任何森林功能启用
  bool get hasAnyForestFeatureEnabled => 
    showFleaMarket || showCampusRecruitment || showSchoolNavigation || 
    showLibrary || showBBS || showAds || showLifeService || showFeedback;

  /// 检查是否有任何首页功能启用
  bool get hasAnyIndexFeatureEnabled => 
    showFinishedTodo || showTodo || showExpense || showClassroom || 
    showExams || showGrades || showIndexServices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          showFinishedTodo == other.showFinishedTodo &&
          showTodo == other.showTodo &&
          showExpense == other.showExpense &&
          showClassroom == other.showClassroom &&
          showExams == other.showExams &&
          showGrades == other.showGrades &&
          showIndexServices == other.showIndexServices &&
          showFleaMarket == other.showFleaMarket &&
          showCampusRecruitment == other.showCampusRecruitment &&
          showSchoolNavigation == other.showSchoolNavigation &&
          showLibrary == other.showLibrary &&
          showBBS == other.showBBS &&
          showAds == other.showAds &&
          showLifeService == other.showLifeService &&
          showFeedback == other.showFeedback &&
          autoSync == other.autoSync &&
          autoRenewalCheckInService == other.autoRenewalCheckInService;

  @override
  int get hashCode =>
      showFinishedTodo.hashCode ^
      showTodo.hashCode ^
      showExpense.hashCode ^
      showClassroom.hashCode ^
      showExams.hashCode ^
      showGrades.hashCode ^
      showIndexServices.hashCode ^
      showFleaMarket.hashCode ^
      showCampusRecruitment.hashCode ^
      showSchoolNavigation.hashCode ^
      showLibrary.hashCode ^
      showBBS.hashCode ^
      showAds.hashCode ^
      showLifeService.hashCode ^
      showFeedback.hashCode ^
      autoSync.hashCode ^
      autoRenewalCheckInService.hashCode;

  @override
  String toString() {
    return 'AppConfig{indexFeatures: $indexDisplaySettings, forestFeatures: $forestFeatureSettings, autoSync: $autoSync, autoRenewalCheckInService: $autoRenewalCheckInService}';
  }
}