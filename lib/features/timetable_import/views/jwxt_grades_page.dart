import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_academic_summary.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_page.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';

Future<void> openJwxtGradesPage(
  BuildContext context, {
  required String semester,
  required JwxtGrades grades,
  required double? gpaMaximum,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => JwxtGradesPage(
        semester: semester,
        grades: grades,
        gpaMaximum: gpaMaximum,
      ),
    ),
  );
}

class JwxtGradesPage extends StatefulWidget {
  const JwxtGradesPage({
    required this.semester,
    required this.grades,
    this.gpaMaximum,
    super.key,
  });

  final String semester;
  final JwxtGrades grades;
  final double? gpaMaximum;

  @override
  State<JwxtGradesPage> createState() => _JwxtGradesPageState();
}

class _JwxtGradesPageState extends State<JwxtGradesPage> {
  String _year = '';
  String _term = '';
  bool _coursesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final years = widget.grades.years;
    final terms = widget.grades.termsFor(_year);
    final grades = widget.grades.filtered(year: _year, term: _term);
    final courses = grades.courseAttempts;
    final count = courses.length;
    final coursesTitle = '课程成绩 · $count 门';
    final scope = _year.isEmpty
        ? widget.semester
        : '$_year 学年 · ${_term.isEmpty ? '全部学期' : _term}';

    return Scaffold(
      appBar: AppBar(title: const Text('个人成绩')),
      body: SafeArea(
        top: false,
        child: AppPageContent(
          child: ListView.separated(
            padding: AppPageContent.padding,
            itemCount: 1 + (_coursesExpanded ? count : 0),
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 0 : AppSpace.md),
            itemBuilder: (context, index) {
              if (index > 0) {
                return _CourseGradeCard(attempts: courses[index - 1]);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(scope, style: text.titleMedium),
                  const SizedBox(height: AppSpace.md),
                  AppAcademicSummary(
                    grades: grades,
                    gpaMaximum: widget.gpaMaximum,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '绩点按课程学分加权估算。同一学期的同一门课只计一次，有已公布的补考成绩时以补考为准。',
                    style: text.bodySmall,
                  ),
                  if (years.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    _GradePair(
                      first: _GradeFilter(
                        key: const ValueKey('academic-year-filter'),
                        label: '学年',
                        allLabel: '全部学年',
                        value: _year,
                        options: years,
                        onChanged: (year) => setState(() {
                          _year = year;
                          _term = '';
                        }),
                      ),
                      second: _GradeFilter(
                        key: ValueKey('academic-term-filter-$_year'),
                        label: '学期',
                        allLabel: '全部学期',
                        value: _term,
                        options: terms,
                        onChanged: terms.isEmpty
                            ? null
                            : (term) => setState(() => _term = term),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  if (count == 0) ...[
                    AppSectionHeader(title: coursesTitle),
                    const AppEmptyState(
                      icon: AppIcons.school,
                      title: '暂无成绩',
                      message: '当前范围内没有课程成绩。',
                    ),
                  ] else
                    Semantics(
                      expanded: _coursesExpanded,
                      child: Pressable(
                        key: const ValueKey('academic-courses-toggle'),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () => setState(
                          () => _coursesExpanded = !_coursesExpanded,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    coursesTitle,
                                    style: text.titleLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              AnimatedRotation(
                                turns: _coursesExpanded ? -0.5 : 0,
                                duration: AppMotion.of(
                                  context,
                                  AppMotion.medium,
                                ),
                                curve: Curves.easeIn,
                                child: const Icon(
                                  AppIcons.chevronDown,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GradeFilter extends StatelessWidget {
  const _GradeFilter({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String allLabel;
  final String value;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  String _labelFor(String option) => option.isEmpty ? allLabel : option;

  Future<void> _select(BuildContext context) async {
    final choice = await showAppSheet<String>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: '选择$label',
        children: [
          AppListGroup(
            children: [
              for (final option in ['', ...options])
                Semantics(
                  selected: option == value,
                  child: AppListRow(
                    icon: AppIcons.calendar,
                    title: _labelFor(option),
                    trailing: option == value
                        ? Icon(
                            AppIcons.check,
                            color: sheetContext.colors.accent,
                          )
                        : const SizedBox.shrink(),
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    if (context.mounted && choice != null && choice != value) {
      onChanged?.call(choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = onChanged == null ? colors.inkFaint : colors.ink;
    return AppFieldLabel(
      label: label,
      child: Pressable(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onChanged == null ? null : () => _select(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _labelFor(value),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Icon(AppIcons.chevronDown, size: 20, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradePair extends StatelessWidget {
  const _GradePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300 ||
            (constraints.maxWidth < 400 &&
                MediaQuery.textScalerOf(context).scale(16) > 22)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: AppSpace.md),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpace.md),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _CourseGradeCard extends StatelessWidget {
  const _CourseGradeCard({required this.attempts});

  final List<JwxtGrade> attempts;

  @override
  Widget build(BuildContext context) {
    final course = attempts.first;
    final text = Theme.of(context).textTheme;
    final period = [
      if (course.year.isNotEmpty) course.year,
      if (course.term.isNotEmpty) course.term,
    ].join(' · ');
    if (attempts.length == 1 && !course.isMakeup) {
      return AppPanel(
        child: _GradeAttempt(grade: course, coursePeriod: period),
      );
    }

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(course.course, style: text.titleMedium),
          if (period.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(period, style: text.bodySmall),
          ],
          for (final attempt in [
            ...attempts.where((grade) => !grade.isMakeup),
            ...attempts.where((grade) => grade.isMakeup),
          ]) ...[
            const SizedBox(height: AppSpace.sm),
            _GradeAttempt(grade: attempt),
          ],
        ],
      ),
    );
  }
}

class _GradeAttempt extends StatelessWidget {
  const _GradeAttempt({required this.grade, this.coursePeriod});

  final JwxtGrade grade;
  final String? coursePeriod;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final standalone = coursePeriod != null;
    final title = standalone
        ? grade.course
        : grade.examType.isEmpty
        ? '考试成绩'
        : grade.examType;
    final score = grade.score.isEmpty ? '未公布' : grade.score;
    final details = [
      if (grade.point case final point?) '绩点 $point',
      if (grade.credit case final credit?) '学分 $credit',
      if (grade.courseType.isNotEmpty) grade.courseType,
      if (standalone && grade.examType.isNotEmpty) grade.examType,
    ];
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: (standalone ? text.titleMedium : text.labelLarge)
                    ?.copyWith(
                      color: grade.isMakeup ? colors.accent : colors.ink,
                    ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  label: '成绩 $score',
                  excludeSemantics: true,
                  child: Text(
                    score,
                    textAlign: TextAlign.end,
                    style: text.titleMedium?.copyWith(
                      color: grade.score.isEmpty
                          ? colors.inkMuted
                          : standalone || grade.isMakeup
                          ? colors.accent
                          : colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (coursePeriod case final period? when period.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Text(period, style: text.bodySmall),
        ],
        if (details.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.xs,
            children: [
              for (final detail in details) Text(detail, style: text.bodySmall),
            ],
          ),
        ],
      ],
    );
    if (standalone) return content;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: grade.isMakeup ? colors.accentSoft : colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: content,
    );
  }
}
