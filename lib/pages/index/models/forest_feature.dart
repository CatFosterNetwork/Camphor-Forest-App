// lib/pages/index/models/forest_feature.dart

import 'package:flutter/material.dart';

class ForestFeature {
  final String abbr;
  final String name;
  final IconData icon;
  final String path;
  final bool enabled;

  const ForestFeature({
    required this.abbr,
    required this.name,
    required this.icon,
    required this.path,
    this.enabled = true,
  });

  factory ForestFeature.fromJson(Map<String, dynamic> json) {
    return ForestFeature(
      abbr: json['abbr'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: _iconFromString(json['icon'] as String? ?? ''),
      path: json['path'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'abbr': abbr,
      'name': name,
      'icon': icon.codePoint.toString(),
      'path': path,
      'enabled': enabled,
    };
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'icon-bus':
        return Icons.directions_bus_outlined;
      case 'icon-qingxushudong':
        return Icons.chat_bubble_outline;
      case 'icon-icon':
        return Icons.nature_people_outlined;
      case 'icon-chaobiaobuchao':
        return Icons.feedback_outlined;
      case 'icon-library':
        return Icons.local_library_outlined;
      case 'icon-fleamarket':
        return Icons.store_outlined;
      case 'icon-recruitment':
        return Icons.work_outline;
      case 'icon-ads':
        return Icons.campaign_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  ForestFeature copyWith({
    String? abbr,
    String? name,
    IconData? icon,
    String? path,
    bool? enabled,
  }) {
    return ForestFeature(
      abbr: abbr ?? this.abbr,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      path: path ?? this.path,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForestFeature &&
        other.abbr == abbr &&
        other.name == name &&
        other.icon == icon &&
        other.path == path &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(abbr, name, icon, path, enabled);
  }

  @override
  String toString() {
    return 'ForestFeature(abbr: $abbr, name: $name, path: $path, enabled: $enabled)';
  }
}
