import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../repositories/class_table_repository.dart';
import '../repositories/api_class_table_repository.dart';
import '../models/class_table.dart';

/// Repository 提供器：依赖 ApiService + SharedPreferences
final classTableRepositoryProvider = Provider<ClassTableRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiClassTableRepository(api, prefs);
});

/// 课表数据 Provider
/// 使用 record 传参：({'xnm': '2024', 'xqm': '12'})
final classTableProvider =
    FutureProvider.family<ClassTable, ({String xnm, String xqm})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(classTableRepositoryProvider);
      return await repo.loadLocal(params.xnm, params.xqm) ??
          await repo.fetchRemote(params.xnm, params.xqm);
    });
