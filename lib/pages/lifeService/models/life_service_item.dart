// lib/pages/lifeService/models/life_service_item.dart

import 'package:flutter/material.dart';

/// 生活服务项目数据模型
class LifeServiceItem {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const LifeServiceItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.onTap,
  });
}