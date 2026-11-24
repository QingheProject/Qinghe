import 'dart:convert';

/// 生成稳定且不暴露内容的编号，供教务导入的课程、安排与考试共用。
///
/// 使用 FNV-1a 64 位：高 32 位与低 32 位分别格式化，因为 Dart 的整数是有符号
/// 64 位，直接对整个值取十六进制会带上负号，长度也不固定。
String jwxtFingerprint(String input) {
  var hash = 0xcbf29ce484222325;
  for (final unit in utf8.encode(input)) {
    hash = (hash ^ unit) * 0x100000001b3;
  }
  final high = (hash >> 32) & 0xffffffff;
  final low = hash & 0xffffffff;
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}
