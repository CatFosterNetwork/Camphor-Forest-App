// lib/pages/school_navigation/providers/bus_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_models.dart';

final busLinesProvider = FutureProvider<List<BusLine>>((ref) async {
  // 模拟网络延迟
  await Future.delayed(const Duration(milliseconds: 500));

  // 返回模拟数据
  return BusLine.getMockData();
});

final realTimeBusDataProvider = StreamProvider<List<BusData>>((ref) async* {
  // 模拟实时数据流
  yield BusData.getMockData();

  // 每5秒更新一次数据
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield _generateUpdatedBusData();
  }
});

List<BusData> _generateUpdatedBusData() {
  // 生成更新的公交车位置数据
  final random = DateTime.now().millisecondsSinceEpoch;

  return [
    BusData(
      id: 'bus_001',
      lineId: '1',
      latitude: 29.82067 + (random % 100) / 100000,
      longitude: 106.42478 + (random % 100) / 100000,
      speed: 20.0 + (random % 20),
      direction: (random % 360).toDouble(),
    ),
    BusData(
      id: 'bus_002',
      lineId: '2',
      latitude: 29.82067 + (random % 150) / 100000,
      longitude: 106.42478 + (random % 150) / 100000,
      speed: 25.0 + (random % 15),
      direction: (random % 360).toDouble(),
    ),
    BusData(
      id: 'bus_003',
      lineId: '3',
      latitude: 29.82067 + (random % 120) / 100000,
      longitude: 106.42478 + (random % 120) / 100000,
      speed: 30.0 + (random % 10),
      direction: (random % 360).toDouble(),
    ),
    if (random % 3 == 0) // 随机添加额外的车辆
      BusData(
        id: 'bus_004',
        lineId: '4',
        latitude: 29.82067 + (random % 80) / 100000,
        longitude: 106.42478 + (random % 80) / 100000,
        speed: 15.0 + (random % 25),
        direction: (random % 360).toDouble(),
      ),
  ];
}

final selectedBusLineProvider = StateProvider<int?>((ref) => null);

final showStopsProvider = StateProvider<bool>((ref) => true);
