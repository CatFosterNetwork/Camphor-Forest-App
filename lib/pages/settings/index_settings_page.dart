// lib/pages/settings/index_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/constants/route_constants.dart';
import '../../core/config/providers/new_core_providers.dart' hide effectiveIsDarkModeProvider;
import '../../core/config/services/app_config_service.dart';
import '../../core/config/providers/theme_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexSettingsPage extends ConsumerWidget {
  const IndexSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    
    // 获取主题色，如果没有主题则使用默认蓝色
    final themeColor = currentTheme?.colorList.isNotEmpty == true 
        ? currentTheme!.colorList[0] 
        : Colors.blue;
    final activeColor = isDarkMode 
        ? themeColor.withAlpha(204) 
        : themeColor;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false, // 设置页面使用纯色背景，保持专业感
      forceStatusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // 强制状态栏图标适配
      appBar: ThemeAwareAppBar(
        title: '主页设置',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 森林功能设置
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '森林功能',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // 森林功能总开关
                      Consumer(
                        builder: (context, ref, child) {
                          final isEnabled = ref.watch(newShouldShowForestFeaturesProvider);
                          return Switch.adaptive(
                            value: isEnabled,
                            onChanged: (value) async {
                              // 切换所有森林功能
                              final prefs = await SharedPreferences.getInstance();
                              final configService = AppConfigService(prefs);
                              
                              // 森林功能列表
                              final forestFeatures = [
                                'forest-showSchoolNavigation',
                                'forest-showBBS', 
                                'forest-showLifeService',
                                'forest-showFeedback',
                                'forest-showFleaMarket',
                                'forest-showCampusRecruitment',
                                'forest-showLibrary',
                                'forest-showAds',
                              ];
                              
                              // 如果要启用，则启用核心功能
                              if (value) {
                                // 启用核心功能
                                await configService.updateConfigItem('forest-showSchoolNavigation', true);
                                await configService.updateConfigItem('forest-showBBS', true);
                                await configService.updateConfigItem('forest-showLifeService', true);
                                await configService.updateConfigItem('forest-showFeedback', true);
                              } else {
                                // 关闭所有森林功能
                                for (final feature in forestFeatures) {
                                  await configService.updateConfigItem(feature, false);
                                }
                              }
                            },
                            activeColor: activeColor,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开启后将在主页显示森林功能区域',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // 课表设置
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '课表显示',
                                            style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '课表组件相关设置',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: Text(
                      '显示课表简览',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '在主页显示今日课程',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现课表显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                  
                  SwitchListTile(
                    title: Text(
                      '启用背景模糊',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '为课表组件启用毛玻璃效果',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现背景模糊开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                ],
              ),
            ),
          ),
          
          // 快捷卡片设置
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快捷卡片',
                                            style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择在主页显示的快捷功能卡片',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: Text(
                      '显示待办',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '在主页显示待办事项',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现待办显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                  
                  SwitchListTile(
                    title: Text(
                      '显示已完成待办',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '开启后将显示已完成的待办事项',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: 实现已完成待办显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                  
                  SwitchListTile(
                    title: Text(
                      '显示考试列表',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '在主页显示即将到来的考试',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现考试列表显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                  
                  SwitchListTile(
                    title: Text(
                      '显示水电余额',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '显示宿舍水电费余额信息',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: 实现水电余额显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                  
                  SwitchListTile(
                    title: Text(
                      '显示空教室',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '显示当前可用的空教室信息',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: 实现空教室显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                  
                  SwitchListTile(
                    title: Text(
                      '显示成绩',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '在主页显示最新成绩信息',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现成绩显示开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                ],
              ),
            ),
          ),
          
          // 快捷操作
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快捷操作',
                                            style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  ListTile(
                    leading: Icon(
                      Icons.table_chart_outlined,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '课表设置',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '配置课表显示和数据',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      size: 16,
                    ),
                    onTap: () => context.push(RouteConstants.classTable),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  ListTile(
                    leading: Icon(
                      Icons.refresh,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '刷新数据',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '重新获取最新数据',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('正在刷新数据...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}