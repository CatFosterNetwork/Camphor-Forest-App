import 'dart:math';

/// 生成指定范围内的随机数
int randomSeedRange(int min, int max, [int? seed]) {
  final random = seed != null ? Random(seed) : Random();
  return min + random.nextInt(max - min + 1);
}
