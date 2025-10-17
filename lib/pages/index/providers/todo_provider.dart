// lib/pages/index/providers/todo_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_item.dart';
import '../../../core/providers/core_providers.dart';

/// 待办事项状态管理
class TodoNotifier extends StateNotifier<List<TodoItem>> {
  final Ref _ref;

  TodoNotifier(this._ref) : super([]) {
    _loadTodos();
  }

  /// 加载待办事项
  Future<void> _loadTodos() async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.getTodo();

      debugPrint('getTodo API 响应: $response');

      // 处理API响应结构
      List<dynamic> todoData = [];
      if (response['success'] == true && response['data'] != null) {
        if (response['data'] is Map<String, dynamic> &&
            response['data']['data'] != null) {
          todoData = response['data']['data'] as List<dynamic>;
        } else if (response['data'] is List<dynamic>) {
          todoData = response['data'] as List<dynamic>;
        }
      }

      final todos = todoData
          .map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint('解析的待办事项数量: ${todos.length}');

      // 按截止时间排序
      todos.sort((a, b) {
        if (a.due == null && b.due == null) return 0;
        if (a.due == null) return 1;
        if (b.due == null) return -1;
        return a.due!.compareTo(b.due!);
      });

      state = todos;
      debugPrint('待办事项加载完成，状态更新: ${state.length} 项');
    } catch (e) {
      // 如果API调用失败，显示空状态
      debugPrint('加载待办事项失败: $e');
      state = [];
    }
  }

  /// 切换待办事项完成状态
  Future<void> toggleTodo(int id) async {
    // 先更新本地状态
    state = state.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(finished: !todo.finished);
      }
      return todo;
    }).toList();

    // 然后调用API
    try {
      final apiService = _ref.read(apiServiceProvider);
      final todo = state.firstWhere((t) => t.id == id);
      await apiService.modifyTodo(id, todo.toJson());
    } catch (e) {
      debugPrint('更新待办事项失败: $e');
      // 如果API调用失败，回滚状态
      state = state.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(finished: !todo.finished);
        }
        return todo;
      }).toList();
    }
  }

  /// 添加待办事项
  Future<void> addTodo(String title, DateTime? due, bool important) async {
    final newTodo = TodoItem(
      id: 0, // 临时ID，后端会分配真实ID
      title: title,
      due: due,
      important: important,
    );

    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.addTodo(newTodo.toJson());

      debugPrint('addTodo API 响应: $response');

      // 如果成功，处理响应数据
      if (response['success'] == true) {
        TodoItem createdTodo;

        // 如果后端返回了创建的数据，使用返回的数据；否则刷新整个列表
        if (response['data'] != null) {
          createdTodo = TodoItem.fromJson(
            response['data'] as Map<String, dynamic>,
          );

          // 添加到状态并重新排序
          final updatedTodos = [...state, createdTodo];
          updatedTodos.sort((a, b) {
            if (a.due == null && b.due == null) return 0;
            if (a.due == null) return 1;
            if (b.due == null) return -1;
            return a.due!.compareTo(b.due!);
          });

          state = updatedTodos;
          debugPrint('待办事项添加成功，使用返回数据，当前总数: ${state.length}');
        } else {
          // 后端没有返回数据，重新加载所有待办事项
          debugPrint('后端返回成功但无数据，重新加载待办事项列表');
          await _loadTodos();
        }
      } else {
        throw Exception('添加失败: ${response['msg'] ?? '未知错误'}');
      }
    } catch (e) {
      debugPrint('添加待办事项失败: $e');
      // API调用失败，不添加到本地
      rethrow; // 重新抛出异常，让UI层处理
    }
  }

  /// 修改待办事项
  Future<void> modifyTodo(int id, TodoItem updatedTodo) async {
    // 先更新本地状态
    final oldState = state;
    state = state.map((todo) {
      return todo.id == id ? updatedTodo : todo;
    }).toList();

    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.modifyTodo(id, updatedTodo.toJson());
    } catch (e) {
      debugPrint('修改待办事项失败: $e');
      // 如果API调用失败，回滚状态
      state = oldState;
    }
  }

  /// 删除待办事项
  Future<void> deleteTodo(int id) async {
    // 先保存原状态
    final oldState = state;
    // 更新本地状态
    state = state.where((todo) => todo.id != id).toList();

    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.deleteTodo(id);
    } catch (e) {
      debugPrint('删除待办事项失败: $e');
      // 如果API调用失败，回滚状态
      state = oldState;
    }
  }

  /// 切换重要性
  Future<void> toggleImportant(int id) async {
    // 先更新本地状态
    final oldState = state;
    state = state.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(important: !todo.important);
      }
      return todo;
    }).toList();

    try {
      final apiService = _ref.read(apiServiceProvider);
      final todo = state.firstWhere((t) => t.id == id);
      await apiService.modifyTodo(id, todo.toJson());
    } catch (e) {
      debugPrint('更新重要性失败: $e');
      // 如果API调用失败，回滚状态
      state = oldState;
    }
  }

  /// 刷新待办事项
  Future<void> refresh() async {
    await _loadTodos();
  }
}

/// 待办事项Provider
final todoProvider = StateNotifierProvider<TodoNotifier, List<TodoItem>>((ref) {
  return TodoNotifier(ref);
});

/// 已逾期的待办事项
final overdueProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);
  final now = DateTime.now();

  return todos.where((todo) {
    return !todo.finished && todo.due != null && todo.due!.isBefore(now);
  }).toList();
});

/// 今天的待办事项
final todayProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  return todos.where((todo) {
    if (todo.finished || todo.due == null) return false;
    return todo.due!.isAfter(now) && todo.due!.isBefore(tomorrow);
  }).toList();
});

/// 明天的待办事项
final tomorrowProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);
  final now = DateTime.now();
  final tomorrow = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));

  return todos.where((todo) {
    if (todo.finished || todo.due == null) return false;
    return todo.due!.isAfter(tomorrow) && todo.due!.isBefore(dayAfterTomorrow);
  }).toList();
});

/// 一周内的待办事项
final thisWeekProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
  final oneWeekLater = now.add(const Duration(days: 7));

  return todos.where((todo) {
    if (todo.finished || todo.due == null) return false;
    return todo.due!.isAfter(now) &&
        todo.due!.isBefore(oneWeekLater) &&
        !todo.due!.isBefore(dayAfterTomorrow);
  }).toList();
});

/// 以后的待办事项
final futureProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);
  final now = DateTime.now();
  final oneWeekLater = now.add(const Duration(days: 7));

  return todos.where((todo) {
    if (todo.finished || todo.due == null) return false;
    return todo.due!.isAfter(oneWeekLater);
  }).toList();
});

/// 无截止时间的待办事项
final noDueTimeProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);

  return todos.where((todo) {
    return !todo.finished && todo.due == null;
  }).toList();
});

/// 已完成的待办事项
final completedProvider = Provider<List<TodoItem>>((ref) {
  final todos = ref.watch(todoProvider);

  return todos.where((todo) => todo.finished).toList();
});

/// 未完成待办事项总数
final incompleteCountProvider = Provider<int>((ref) {
  final todos = ref.watch(todoProvider);
  return todos.where((todo) => !todo.finished).length;
});
