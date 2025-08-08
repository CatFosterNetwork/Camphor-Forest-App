// lib/pages/life_service/life_service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import 'models/life_service_item.dart';
import 'widgets/life_service_list.dart';

/// 生活服务主页面
class LifeServiceScreen extends ConsumerWidget {
  const LifeServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 定义功能列表
    final List<LifeServiceItem> functionList = [
      LifeServiceItem(
        id: '1',
        name: '成绩查询',
        icon: Icons.school_outlined,
        description: '查询考试成绩以及打印成绩单',
        onTap: () => context.push(RouteConstants.grade),
      ),
      LifeServiceItem(
        id: '2',
        name: '空教室查询',
        icon: Icons.meeting_room_outlined,
        description: '自习时间',
        onTap: () => context.push(RouteConstants.classroom),
      ),
      LifeServiceItem(
        id: '3',
        name: '考试查询',
        icon: Icons.quiz_outlined,
        description: '查看考试列表',
        onTap: () => context.push(RouteConstants.exams),
      ),
      LifeServiceItem(
        id: '4',
        name: '水电查询',
        icon: Icons.flash_on_outlined,
        description: '重新绑定宿舍水电费',
        onTap: () => context.push(RouteConstants.dormBind),
      ),
      LifeServiceItem(
        id: '5',
        name: '校历查询',
        icon: Icons.calendar_today_outlined,
        description: '追踪学校最新动态',
        onTap: () => context.push(RouteConstants.calendar),
      ),
    ];

    return ThemeAwareScaffold(
      pageType: PageType.settings,  // 使用设置页面类型，获得浅灰色背景
      useBackground: false,  // 使用纯色背景，保持专业感
      appBar: ThemeAwareAppBar(
        title: '生活服务',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 功能列表卡片
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: LifeServiceList(items: functionList),
          ),
        ],
      ),
    );
  }

}