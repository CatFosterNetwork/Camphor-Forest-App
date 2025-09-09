import 'dart:ui';
import 'package:flutter/material.dart';

class ForestFeatures extends StatelessWidget {
  final bool blur;
  final bool darkMode;
  final List<ForestFeature> features;
  const ForestFeatures({
    super.key,
    required this.blur,
    required this.darkMode,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    final grid = GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: features.map((f) => _buildItem(context, f)).toList(),
    );

    if (!blur) {
      return Container(padding: const EdgeInsets.all(12), child: grid);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: darkMode
                ? const Color(0xFF2A2A2A).withAlpha(217)
                : Colors.white.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: grid,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, ForestFeature feature) {
    final color = darkMode ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: feature.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, color: color),
          const SizedBox(height: 4),
          Text(feature.name, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class ForestFeature {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  ForestFeature({required this.name, required this.icon, required this.onTap});
}
