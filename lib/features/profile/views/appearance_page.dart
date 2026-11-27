import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_page.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

class AppearancePage extends GetView<AppearanceController> {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外观')),
      body: SafeArea(
        top: false,
        child: Obx(
          () => AppPageContent(
            child: ListView(
              padding: AppPageContent.padding,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChoiceSection<AppearanceThemeMode>(
                      title: '主题',
                      selected: controller.themeMode.value,
                      onChanged: controller.setThemeMode,
                      options: [
                        _AppearanceOption(
                          value: AppearanceThemeMode.system,
                          label: '跟随系统',
                          preview: _ThemePreview.system(
                            controller.accentTone.value,
                          ),
                        ),
                        _AppearanceOption(
                          value: AppearanceThemeMode.light,
                          label: '浅色',
                          preview: _ThemePreview.light(
                            controller.accentTone.value,
                          ),
                        ),
                        _AppearanceOption(
                          value: AppearanceThemeMode.dark,
                          label: '深色',
                          preview: _ThemePreview.dark(
                            controller.accentTone.value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    _ChoiceSection<AppAccentTone>(
                      title: '主题配色',
                      selected: controller.accentTone.value,
                      onChanged: controller.setAccentTone,
                      options: const [
                        _AppearanceOption(
                          value: AppAccentTone.qinghe,
                          label: '青禾',
                          preview: _AccentPreview(AppAccentTone.qinghe),
                        ),
                        _AppearanceOption(
                          value: AppAccentTone.ocean,
                          label: '海蓝',
                          preview: _AccentPreview(AppAccentTone.ocean),
                        ),
                        _AppearanceOption(
                          value: AppAccentTone.violet,
                          label: '暮紫',
                          preview: _AccentPreview(AppAccentTone.violet),
                        ),
                        _AppearanceOption(
                          value: AppAccentTone.amber,
                          label: '暖橙',
                          preview: _AccentPreview(AppAccentTone.amber),
                        ),
                        _AppearanceOption(
                          value: AppAccentTone.rose,
                          label: '玫瑰',
                          preview: _AccentPreview(AppAccentTone.rose),
                        ),
                        _AppearanceOption(
                          value: AppAccentTone.monochrome,
                          label: '黑白',
                          preview: _AccentPreview(AppAccentTone.monochrome),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceOption<T> {
  const _AppearanceOption({
    required this.value,
    required this.label,
    required this.preview,
  });

  final T value;
  final String label;
  final Widget preview;
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<_AppearanceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelSize = Theme.of(context).textTheme.labelSmall!.fontSize!;
    final longestLabel = options
        .map((option) => option.label.length)
        .reduce(math.max);
    final minWidth = math.max(
      84.0,
      MediaQuery.textScalerOf(context).scale(labelSize) * longestLabel + 20,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpace.sm;
            final preferredColumns =
                options.length > 3 && constraints.maxWidth < 560
                ? 3
                : options.length;
            final fittingColumns =
                ((constraints.maxWidth + gap) / (minWidth + gap)).floor();
            final columnCount = fittingColumns >= preferredColumns
                ? preferredColumns
                : fittingColumns.clamp(1, 3);
            final width =
                (constraints.maxWidth - gap * (columnCount - 1)) / columnCount;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in options)
                  SizedBox(
                    width: width,
                    child: _OptionCard(
                      label: option.label,
                      selected: option.value == selected,
                      onTap: () => onChanged(option.value),
                      child: option.preview,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onTap: selected ? null : onTap,
      selected: selected,
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.medium),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: selected ? colors.accent : colors.line,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? colors.accent : colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentPreview extends StatelessWidget {
  const _AccentPreview(this.tone);

  final AppAccentTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkFor(tone)
        : AppColors.lightFor(tone);
    return Container(
      width: 68,
      height: 48,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview.light(this.tone) : light = true, split = false;
  const _ThemePreview.dark(this.tone) : light = false, split = false;
  const _ThemePreview.system(this.tone) : light = true, split = true;

  final AppAccentTone tone;
  final bool light;
  final bool split;

  @override
  Widget build(BuildContext context) {
    if (split) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeSwatch(light: true, half: true, tone: tone),
            _ThemeSwatch(light: false, half: true, tone: tone),
          ],
        ),
      );
    }
    return _ThemeSwatch(light: light, tone: tone);
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.light,
    required this.tone,
    this.half = false,
  });

  final bool light;
  final AppAccentTone tone;
  final bool half;

  @override
  Widget build(BuildContext context) {
    final palette = light ? AppColors.lightFor(tone) : AppColors.darkFor(tone);
    return Container(
      width: half ? 34 : 68,
      height: 48,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: half ? null : BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 5,
            decoration: BoxDecoration(
              color: palette.ink,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Spacer(),
          Container(
            height: 17,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}
