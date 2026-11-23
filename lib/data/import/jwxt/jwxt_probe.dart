import 'dart:convert';

/// 课表接口的字段探测，用于核对学校接口是否改版。
///
/// 只输出字段名、类型和条数，不输出任何字段取值，因此可以安全地写进日志。
abstract final class JwxtProbe {
  static String describe(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return '响应不是 JSON，长度 ${body.length}，开头是否为 HTML：'
          '${body.trimLeft().toLowerCase().startsWith('<')}';
    }
    return switch (decoded) {
      final List<Object?> list => '根节点为数组，共 ${list.length} 条；${_fields(list)}',
      final Map<String, dynamic> map =>
        '根节点为对象，字段 ${map.keys.join(', ')}；${_fields(_lists(map))}',
      _ => '根节点为 ${decoded.runtimeType}。',
    };
  }

  static List<Object?> _lists(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      if (entry.value case final List<Object?> list) {
        if (list.isEmpty) return const [];
        if (list.first is Map<String, dynamic>) {
          return list;
        }
      }
    }
    return const [];
  }

  static String _fields(List<Object?> list) {
    final items = [
      for (final item in list)
        if (item is Map<String, dynamic>) item,
    ];
    if (items.isEmpty) return '没有可解析的条目。';
    final counts = <String, (String, int)>{};
    for (final item in items) {
      for (final entry in item.entries) {
        final type = entry.value == null
            ? 'null'
            : entry.value.runtimeType.toString();
        final previous = counts[entry.key];
        counts[entry.key] = (type, (previous?.$2 ?? 0) + 1);
      }
    }
    final fields = [
      for (final entry in counts.entries)
        '${entry.key}:${entry.value.$1}'
            '${entry.value.$2 == items.length ? '' : '(${entry.value.$2}/${items.length})'}',
    ];
    return '共 ${items.length} 条，字段 ${fields.join(', ')}';
  }
}
