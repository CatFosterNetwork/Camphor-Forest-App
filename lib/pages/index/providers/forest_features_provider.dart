// lib/pages/index/providers/forest_features_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/new_core_providers.dart';
import '../../../core/constants/route_constants.dart';
import '../models/forest_feature.dart';

// 森林功能配置已迁移到AppConfig中管理

/// 固定的森林功能列表（前四个核心功能）
final _defaultFeatures = [
  ForestFeature(
    abbr: 'SchoolNavigation',
    name: '爱上校车',
    icon: Icons.directions_bus_outlined,
    path: RouteConstants.schoolNavigation,
  ),
  ForestFeature(
    abbr: 'BBS',
    name: '情绪树洞',
    icon: Icons.chat_bubble_outline,
    path: RouteConstants.bbs,
  ),
  ForestFeature(
    abbr: 'LifeService',
    name: '校园生活',
    icon: Icons.nature_people_outlined,
    path: RouteConstants.lifeService,
  ),
  ForestFeature(
    abbr: 'Feedback',
    name: '反馈改进',
    icon: Icons.feedback_outlined,
    path: RouteConstants.feedback,
  ),
];

/// 所有可用的森林功能
final allForestFeaturesProvider = Provider<List<ForestFeature>>((ref) {
  // 这里可以从API获取，目前使用默认列表
  return _defaultFeatures;
});

/// 当前启用的森林功能（只包含前四个核心功能）
final enabledForestFeaturesProvider = Provider<List<ForestFeature>>((ref) {
  final allFeatures = ref.watch(allForestFeaturesProvider);
  final appConfigAsync = ref.watch(appConfigNotifierProvider);

  return appConfigAsync.when(
    data: (appConfig) {
      return allFeatures.where((feature) {
        switch (feature.abbr) {
          case 'SchoolNavigation':
            return appConfig.showSchoolNavigation;
          case 'BBS':
            return appConfig.showBBS;
          case 'LifeService':
            return appConfig.showLifeService;
          case 'Feedback':
            return appConfig.showFeedback;
          default:
            return false;
        }
      }).toList();
    },
    loading: () => [], // 加载中时返回空列表
    error: (_, _) => [], // 错误时返回空列表
  );
});

/// 森林功能组件是否应该显示（使用新的配置系统）
final shouldShowForestFeaturesProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);

  return appConfigAsync.when(
    data: (appConfig) => appConfig.hasAnyForestFeatureEnabled,
    loading: () => false, // 加载中时不显示
    error: (_, _) => false, // 错误时不显示
  );
});

/// 模拟API获取功能列表
final forestFeaturesApiProvider = FutureProvider<List<ForestFeature>>((
  ref,
) async {
  // 模拟网络延迟
  await Future.delayed(const Duration(milliseconds: 500));

  // 模拟API失败，返回默认列表
  return _defaultFeatures;
});
