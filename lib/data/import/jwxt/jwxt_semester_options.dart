/// 教务系统学生课表页里的学年与学期选项。
///
/// 学期编码由学校决定，应用不硬编码，只解析页面上的下拉框；这样学期新增、
/// 编码变化都不需要改代码。
class JwxtSemesterChoice {
  const JwxtSemesterChoice({
    required this.value,
    required this.label,
    required this.selected,
  });

  final String value;
  final String label;
  final bool selected;
}

class JwxtSemesterOptions {
  JwxtSemesterOptions({
    required List<JwxtSemesterChoice> years,
    required List<JwxtSemesterChoice> terms,
    required this.defaultYear,
    required this.defaultTerm,
  }) : years = List.unmodifiable(years),
       terms = List.unmodifiable(terms);

  final List<JwxtSemesterChoice> years;
  final List<JwxtSemesterChoice> terms;
  final String? defaultYear;
  final String? defaultTerm;

  /// 常见的纯数字学期标签，仅在页面只给出数字时使用。
  static const _termNames = {'3': '第一学期', '12': '第二学期', '16': '第三学期'};

  String labelOf(String? year, String? term) {
    final yearLabel = _labelIn(years, year);
    final termLabel = _termLabelIn(terms, term);
    return [yearLabel, termLabel].where((part) => part.isNotEmpty).join(' ');
  }

  static String _labelIn(List<JwxtSemesterChoice> choices, String? value) {
    for (final choice in choices) {
      if (choice.value == value) return choice.label;
    }
    return '';
  }

  static String _termLabelIn(List<JwxtSemesterChoice> choices, String? value) {
    for (final choice in choices) {
      if (choice.value != value) continue;
      // 页面常常只给出 1／2／3 这类数字标签，按学期编码补成可读名称。
      if (RegExp(r'^\d+$').hasMatch(choice.label)) {
        return _termNames[choice.value] ?? choice.label;
      }
      return choice.label;
    }
    return '';
  }

  /// 从课表页 HTML 读取 `xnm`（学年）与 `xqm`（学期）下拉框。
  factory JwxtSemesterOptions.parse(String html) {
    final years = _choices(_select(html, 'xnm'));
    final terms = _choices(_select(html, 'xqm'));
    if (years.isEmpty || terms.isEmpty) {
      throw const FormatException('无法从教务系统页面读取学年与学期列表。');
    }
    return JwxtSemesterOptions(
      years: years,
      terms: terms,
      defaultYear: _selected(years),
      defaultTerm: _selected(terms),
    );
  }

  static final _selectPattern = RegExp(
    r'<select\b[^>]*>[\s\S]*?</select>',
    caseSensitive: false,
  );
  static final _optionPattern = RegExp(
    r'<option\b([^>]*)>([\s\S]*?)</option>',
    caseSensitive: false,
  );
  static final _valuePattern = RegExp(
    r'''\bvalue\s*=\s*["']([^"']*)["']''',
    caseSensitive: false,
  );
  static final _tagPattern = RegExp(r'<[^>]+>');

  static String _select(String html, String name) {
    for (final block in _selectPattern.allMatches(html)) {
      final open = block.group(0)!.substring(0, block.group(0)!.indexOf('>'));
      if (_names(open, name)) return block.group(0)!;
    }
    return '';
  }

  static bool _names(String openTag, String name) {
    return RegExp(
      '\\b(?:id|name)\\s*=\\s*["\']$name["\']',
      caseSensitive: false,
    ).hasMatch(openTag);
  }

  static List<JwxtSemesterChoice> _choices(String select) {
    final result = <JwxtSemesterChoice>[];
    for (final option in _optionPattern.allMatches(select)) {
      final attributes = option.group(1)!;
      final label = _clean(option.group(2)!);
      final value = _valuePattern.firstMatch(attributes)?.group(1) ?? label;
      if (value.isEmpty && label.isEmpty) continue;
      result.add(
        JwxtSemesterChoice(
          value: value,
          label: label.isEmpty ? value : label,
          selected: RegExp(
            r'\bselected\b',
            caseSensitive: false,
          ).hasMatch(attributes),
        ),
      );
    }
    return result;
  }

  static String? _selected(List<JwxtSemesterChoice> choices) {
    for (final choice in choices) {
      if (choice.selected) return choice.value;
    }
    return choices.isEmpty ? null : choices.first.value;
  }

  static String _clean(String text) {
    return text
        .replaceAll(_tagPattern, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
