// lib/pages/lifeService/widgets/expense_detail_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/providers/theme_config_provider.dart';

/// 水电费详情卡片组件
class ExpenseDetailCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final bool useAcrylicEffect;

  const ExpenseDetailCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onTap,
    this.useAcrylicEffect = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
          ],
        ),

        const SizedBox(height: 20),

        // 内容
        child,
      ],
    );

    Widget styledCard;

    if (useAcrylicEffect) {
      // 使用亚克力材质效果
      styledCard = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDarkMode ? 76 : 20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: cardContent,
          ),
        ),
      );
    } else {
      // 使用普通材质效果
      styledCard = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDarkMode ? 76 : 20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDarkMode
              ? Border.all(color: Colors.white.withAlpha(26), width: 1)
              : null,
        ),
        child: cardContent,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: styledCard,
      ),
    );
  }
}
