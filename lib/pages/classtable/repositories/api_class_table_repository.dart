import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_table.dart';
import '../../../core/services/api_service.dart';
import 'class_table_repository.dart';

class ApiClassTableRepository implements ClassTableRepository {
  final ApiService api;
  final SharedPreferences prefs;
  ApiClassTableRepository(this.api, this.prefs);

  String _key(String xnm, String xqm) => 'classTable-$xnm-$xqm';

  @override
  Future<ClassTable> fetchRemote(String xnm, String xqm) async {
    debugPrint('开始从远程获取课表数据 (xnm: $xnm, xqm: $xqm)');

    try {
      // 使用原有的API方法获取数据
      final responseData = await api.fetchClassTable(xnm: xnm, xqm: xqm);
      debugPrint('获取到原始课表数据类型: ${responseData.runtimeType}');

      // 使用增强的fromRawJson方法解析数据
      debugPrint('开始解析课表数据...');
      final table = ClassTable.fromRawJson(responseData);

      // 输出解析结果摘要
      int totalCourses = 0;
      table.weekTable.forEach((week, dayMap) {
        dayMap.forEach((day, courses) {
          totalCourses += courses.length;
        });
      });

      debugPrint('解析完成, 总周数: ${table.weekTable.length}, 总课程数: $totalCourses');

      // 如果成功获取到课表信息，先清空本地缓存再保存新数据
      if (totalCourses > 0) {
        debugPrint('成功获取课表数据，先清空本地缓存');
        await clearLocal(xnm, xqm);

        debugPrint('开始保存新的课表数据到本地缓存');
        await saveLocal(xnm, xqm, table);
        debugPrint('新课表数据已保存到本地缓存');
      } else {
        debugPrint('未解析到有效课程，不保存到本地缓存');
      }

      return table;
    } catch (e, stackTrace) {
      debugPrint('获取课表数据时出错: $e');
      debugPrint('错误堆栈: $stackTrace');

      // 尝试从本地加载
      final localData = await loadLocal(xnm, xqm);
      if (localData != null) {
        debugPrint('远程获取失败，使用本地缓存数据');
        return localData;
      }

      // 如果本地也没有，则抛出异常
      rethrow;
    }
  }

  @override
  Future<ClassTable?> loadLocal(String xnm, String xqm) async {
    debugPrint('尝试从本地加载课表 (xnm: $xnm, xqm: $xqm)');

    try {
      final str = prefs.getString(_key(xnm, xqm));
      if (str == null || str.isEmpty) {
        debugPrint('本地无缓存数据');
        return null;
      }

      debugPrint('找到本地缓存数据, 长度: ${str.length} 字节');

      // 确保JSON字符串有效
      if (str == '{}' || str == '[]') {
        debugPrint('本地缓存数据为空对象或数组');
        return null;
      }

      // 解析JSON
      final json = jsonDecode(str);
      if (json is! Map<String, dynamic>) {
        debugPrint('本地缓存数据格式错误: 不是有效的JSON对象');
        return null;
      }

      // 解析本地数据
      final table = ClassTable.fromFormattedJson(json, xnm: xnm, xqm: xqm);

      // 输出解析后的课表信息
      int totalCourses = 0;
      table.weekTable.forEach((week, dayMap) {
        dayMap.forEach((day, courses) {
          totalCourses += courses.length;
        });
      });

      debugPrint(
        '本地数据解析完成, 总周数: ${table.weekTable.length}, 总课程数: $totalCourses',
      );

      return table;
    } catch (e) {
      debugPrint('加载本地课表数据失败: $e');
      return null;
    }
  }

  @override
  Future<void> saveLocal(String xnm, String xqm, ClassTable data) async {
    try {
      debugPrint('保存课表数据到本地 (xnm: $xnm, xqm: $xqm)');
      final json = data.toJson();
      final jsonStr = jsonEncode(json);
      debugPrint('准备保存的数据大小: ${jsonStr.length} 字节');

      if (jsonStr.length <= 2) {
        debugPrint('警告: 保存的数据可能为空');
      }

      await prefs.setString(_key(xnm, xqm), jsonStr);
      debugPrint('课表数据保存成功');
    } catch (e) {
      debugPrint('保存课表数据失败: $e');
    }
  }

  /// 清空本地缓存的课表数据
  @override
  Future<void> clearLocal(String xnm, String xqm) async {
    try {
      debugPrint('清空本地课表缓存 (xnm: $xnm, xqm: $xqm)');
      await prefs.remove(_key(xnm, xqm));
      debugPrint('本地课表缓存已清空');
    } catch (e) {
      debugPrint('清空本地课表缓存失败: $e');
    }
  }
}
