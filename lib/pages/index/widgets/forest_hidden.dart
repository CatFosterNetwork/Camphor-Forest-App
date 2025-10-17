// lib/pages/index/widgets/forest_hidden.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/providers/new_core_providers.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/constants/route_constants.dart';

import '../providers/forest_features_provider.dart';
import '../models/forest_feature.dart';
import '../../../core/models/theme_model.dart' as theme_model;

class ForestHidden extends ConsumerWidget {
  final bool blur;
  final bool darkMode;

  const ForestHidden({super.key, required this.blur, required this.darkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowForestFeaturesProvider);
    final enabledFeatures = ref.watch(enabledForestFeaturesProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final textColor = darkMode ? Colors.white70 : Colors.black87;
    final fadedTextColor = darkMode
        ? Colors.grey.shade500
        : Colors.grey.shade600;

    Widget child = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '树林荫下',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: textColor, size: 20),
                onPressed: () => context.push(RouteConstants.options),
                tooltip: '设置',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 功能网格
          if (enabledFeatures.isNotEmpty)
            _buildFeaturesGrid(
              context,
              enabledFeatures,
              textColor,
              currentTheme,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无启用的功能',
                  style: TextStyle(color: fadedTextColor, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );

    if (blur) {
      child = RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: darkMode
                    ? const Color(0xFF2A2A2A).withAlpha(217)
                    : Colors.white.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
                border: darkMode
                    ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      );
    } else {
      child = Container(
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.grey.shade900.withAlpha(230)
              : Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildFeaturesGrid(
    BuildContext context,
    List<ForestFeature> features,
    Color textColor,
    theme_model.Theme? currentTheme,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];

        // 使用主题色彩或默认色彩
        Color primaryColor = Colors.blue;
        if (currentTheme != null && currentTheme.colorList.isNotEmpty) {
          primaryColor = currentTheme.colorList[0];
        }

        return GestureDetector(
          onTap: () => context.push(feature.path),
          child: Container(
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withAlpha(76), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(feature.icon, color: primaryColor, size: 24),
                const SizedBox(height: 4),
                Text(
                  feature.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
