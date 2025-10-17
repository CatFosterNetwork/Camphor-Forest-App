// lib/pages/index/models/todo_item.dart

import 'package:flutter/material.dart';

/// 待办事项数据模型
class TodoItem {
  final int id;
  final String title;
  final DateTime? due;
  final bool important;
  final bool finished;

  const TodoItem({
    required this.id,
    required this.title,
    this.due,
    this.important = false,
    this.finished = false,
  });

  /// 创建副本并修改部分属性
  TodoItem copyWith({
    int? id,
    String? title,
    DateTime? due,
    bool? important,
    bool? finished,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      due: due ?? this.due,
      important: important ?? this.important,
      finished: finished ?? this.finished,
    );
  }

  /// 从JSON创建实例
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDue;
    if (json['due'] != null) {
      if (json['due'] is String) {
        parsedDue = DateTime.tryParse(json['due']);
      } else if (json['due'] is int) {
        parsedDue = DateTime.fromMillisecondsSinceEpoch(json['due']);
      }
    }

    return TodoItem(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] as int? ?? 0),
      title: json['title'] as String? ?? '',
      due: parsedDue,
      important: json['important'] as bool? ?? false,
      finished: json['finished'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'due': due?.toIso8601String(),
      'important': important,
      'finished': finished,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoItem &&
        other.id == id &&
        other.title == title &&
        other.due == due &&
        other.important == important &&
        other.finished == finished;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, due, important, finished);
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, title: $title, due: $due, important: $important, finished: $finished)';
  }
}

/// 待办事项类型枚举
enum TodoCategory {
  overdue, // 已逾期
  today, // 今天
  tomorrow, // 明天
  thisWeek, // 一周内
  future, // 以后
  noDueTime, // 无截止时间
  completed, // 已完成
}

/// 待办事项分类扩展
extension TodoCategoryExtension on TodoCategory {
  String get displayName {
    switch (this) {
      case TodoCategory.overdue:
        return '已逾期';
      case TodoCategory.today:
        return '今天';
      case TodoCategory.tomorrow:
        return '明天';
      case TodoCategory.thisWeek:
        return '一周内';
      case TodoCategory.future:
        return '以后';
      case TodoCategory.noDueTime:
        return '无截止时间';
      case TodoCategory.completed:
        return '已完成';
    }
  }

  IconData get icon {
    switch (this) {
      case TodoCategory.overdue:
        return Icons.warning;
      case TodoCategory.today:
        return Icons.today;
      case TodoCategory.tomorrow:
        return Icons.event;
      case TodoCategory.thisWeek:
        return Icons.date_range;
      case TodoCategory.future:
        return Icons.schedule;
      case TodoCategory.noDueTime:
        return Icons.event_available;
      case TodoCategory.completed:
        return Icons.check_circle;
    }
  }
}
