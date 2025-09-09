// lib/pages/lifeService/widgets/life_service_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../models/life_service_item.dart';
import 'life_service_list_item.dart';

/// 生活服务列表组件
class LifeServiceList extends ConsumerWidget {
  final List<LifeServiceItem> items;

  const LifeServiceList({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            LifeServiceListItem(
              item: items[i],
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1) // 不是最后一个项目时添加分隔线
              Divider(
                height: 1,
                thickness: 0.5,
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                indent: 80, // 从图标后开始分隔线
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}
