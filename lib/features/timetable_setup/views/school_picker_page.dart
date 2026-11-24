import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/sources/school_registry.dart';
import 'package:qinghe_app/data/sources/school_source.dart';

/// 选择学校：可搜索、按首字母分组，右侧字母索引快速跳转。
///
/// 列表来自已适配学校的登记表；列表之外的学校可手动填写，仅使用文件导入。
class SchoolPickerPage extends StatefulWidget {
  const SchoolPickerPage({this.selected = '', super.key});

  final String selected;

  @override
  State<SchoolPickerPage> createState() => _SchoolPickerPageState();
}

class _SchoolPickerPageState extends State<SchoolPickerPage> {
  static const _headerHeight = 30.0;
  static const _rowHeight = 52.0;

  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  List<SchoolSource> get _matches {
    final query = _query.toLowerCase();
    final sources = SchoolRegistry.sources;
    if (query.isEmpty) return sources;
    return [
      for (final source in sources)
        if (source.school.toLowerCase().contains(query) ||
            source.initial.toLowerCase() == query)
          source,
    ];
  }

  /// 按首字母分组，字母顺序排列。
  Map<String, List<SchoolSource>> get _groups {
    final groups = <String, List<SchoolSource>>{};
    for (final source in _matches) {
      (groups[source.initial.toUpperCase()] ??= []).add(source);
    }
    for (final list in groups.values) {
      list.sort((a, b) => a.school.compareTo(b.school));
    }
    final keys = groups.keys.toList()..sort();
    return {for (final key in keys) key: groups[key]!};
  }

  void _pick(String school) => Get.back<Object?>(result: school);

  /// 每个字母分组的滚动偏移，与列表里的固定行高一一对应。
  Map<String, double> _offsets(Map<String, List<SchoolSource>> groups) {
    final offsets = <String, double>{};
    var top = 0.0;
    for (final entry in groups.entries) {
      offsets[entry.key] = top;
      top += _headerHeight + entry.value.length * _rowHeight;
    }
    return offsets;
  }

  void _jumpTo(String letter) {
    final offsets = _offsets(_groups);
    final target = offsets[letter];
    if (target == null || !_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _scroll.animateTo(
      target.clamp(0.0, max),
      duration: AppMotion.of(context, const Duration(milliseconds: 240)),
      curve: AppMotion.emphasized,
    );
  }

  /// 手动填写列表之外的学校。
  Future<void> _enterOtherSchool() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: AppMotion.style(context),
      builder: (_) => _OtherSchoolSheet(initial: _query),
    );
    if (!mounted || name == null || name.isEmpty) return;
    _pick(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final groups = _groups;
    final letters = groups.keys.toList();
    final selected = widget.selected.trim();

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(title: const Text('选择学校'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    key: const ValueKey('school-search-field'),
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    style: text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: '搜索学校名称或首字母',
                      prefixIcon: Icon(
                        AppIcons.search,
                        size: 20,
                        color: colors.inkMuted,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清空搜索',
                              onPressed: () => setState(_search.clear),
                              icon: const Icon(AppIcons.close, size: 18),
                            ),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: groups.isEmpty
                      ? _EmptyResult(
                          query: _query,
                          onUseQuery: () => _pick(_query),
                          onManual: _enterOtherSchool,
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              key: const ValueKey('school-list'),
                              controller: _scroll,
                              padding: const EdgeInsets.only(right: 26),
                              itemCount:
                                  groups.length * 1 +
                                  groups.values.fold<int>(
                                    0,
                                    (sum, list) => sum + list.length,
                                  ),
                              itemBuilder: (context, index) {
                                var cursor = 0;
                                for (final entry in groups.entries) {
                                  if (index == cursor) {
                                    return _LetterHeader(
                                      letter: entry.key,
                                      count: entry.value.length,
                                      height: _headerHeight,
                                    );
                                  }
                                  cursor++;
                                  for (final source in entry.value) {
                                    if (index == cursor) {
                                      return SizedBox(
                                        height: _rowHeight,
                                        child: _SchoolRow(
                                          source: source,
                                          selected: source.school == selected,
                                          onTap: () => _pick(source.school),
                                        ),
                                      );
                                    }
                                    cursor++;
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              child: _LetterIndex(
                                letters: letters,
                                onSelected: _jumpTo,
                              ),
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: AppButton(
                    label: '找不到学校？手动填写',
                    tone: AppButtonTone.secondary,
                    expand: true,
                    dense: true,
                    icon: AppIcons.edit,
                    onPressed: _enterOtherSchool,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterHeader extends StatelessWidget {
  const _LetterHeader({
    required this.letter,
    required this.count,
    required this.height,
  });

  final String letter;
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: ValueKey('school-letter-$letter'),
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: colors.canvas,
      child: Text(
        letter,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.inkFaint,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final SchoolSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Pressable(
        key: ValueKey('school-${source.school}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: selected ? colors.accentSoft : Colors.transparent,
        selected: selected,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  source.school,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(AppIcons.check, size: 18, color: colors.accent)
              else
                Icon(AppIcons.chevronRight, size: 16, color: colors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterIndex extends StatelessWidget {
  const _LetterIndex({required this.letters, required this.onSelected});

  final List<String> letters;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (letters.length < 2) return const SizedBox.shrink();
    return Container(
      width: 26,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemHeight = constraints.maxHeight / letters.length;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => onSelected(
              letters[(details.localPosition.dy / itemHeight).floor().clamp(
                0,
                letters.length - 1,
              )],
            ),
            onVerticalDragUpdate: (details) => onSelected(
              letters[(details.localPosition.dy / itemHeight).floor().clamp(
                0,
                letters.length - 1,
              )],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final letter in letters)
                  SizedBox(
                    height: itemHeight,
                    child: Center(
                      child: Text(
                        letter,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({
    required this.query,
    required this.onUseQuery,
    required this.onManual,
  });

  final String query;
  final VoidCallback onUseQuery;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Icon(AppIcons.school, size: 32, color: colors.inkFaint),
          const SizedBox(height: AppSpace.md),
          Text(
            query.isEmpty ? '没有可用的学校' : '没有找到「$query」',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '列表之外的学校不能用教务系统导入，仍可用 JSON 导入课表。',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpace.lg),
          if (query.isNotEmpty)
            AppButton(label: '使用「$query」', expand: true, onPressed: onUseQuery)
          else
            AppButton(label: '手动填写学校', expand: true, onPressed: onManual),
        ],
      ),
    );
  }
}

class _OtherSchoolSheet extends StatefulWidget {
  const _OtherSchoolSheet({required this.initial});

  final String initial;

  @override
  State<_OtherSchoolSheet> createState() => _OtherSchoolSheetState();
}

class _OtherSchoolSheetState extends State<_OtherSchoolSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = _controller.text.trim();
    return AnimatedPadding(
      duration: AppMotion.of(context, AppMotion.fast),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheet(
        title: '手动填写学校',
        subtitle: '列表之外的学校不能使用教务系统，可用 JSON 导入课表。',
        showClose: false,
        footer: AppButton(
          label: '使用该学校',
          expand: true,
          onPressed: name.isEmpty
              ? null
              : () => Navigator.of(context).pop(name),
        ),
        children: [
          TextField(
            key: const ValueKey('school-other-field'),
            controller: _controller,
            autofocus: true,
            maxLength: 80,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (name.isNotEmpty) Navigator.of(context).pop(name);
            },
            style: text.bodyMedium,
            decoration: const InputDecoration(
              hintText: '填写学校名称',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
