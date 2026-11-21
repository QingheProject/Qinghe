import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

class AppearancePage extends GetView<AppearanceController> {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      appBar: AppBar(title: const Text('外观与布局'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChoiceSection<AppearanceThemeMode>(
                        title: '主题',
                        selected: controller.themeMode.value,
                        onChanged: controller.setThemeMode,
                        options: const [
                          _AppearanceOption(
                            value: AppearanceThemeMode.system,
                            label: '跟随系统',
                            preview: _ThemePreview.system(),
                          ),
                          _AppearanceOption(
                            value: AppearanceThemeMode.light,
                            label: '浅色',
                            preview: _ThemePreview.light(),
                          ),
                          _AppearanceOption(
                            value: AppearanceThemeMode.dark,
                            label: '深色',
                            preview: _ThemePreview.dark(),
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
                        ],
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _ChoiceSection<BottomBarStyle>(
                        title: '底栏形态',
                        selected: controller.bottomBarStyle.value,
                        onChanged: controller.setBottomBarStyle,
                        options: const [
                          _AppearanceOption(
                            value: BottomBarStyle.floating,
                            label: '悬浮',
                            preview: _BarShapePreview(floating: true),
                          ),
                          _AppearanceOption(
                            value: BottomBarStyle.fixed,
                            label: '贴底',
                            preview: _BarShapePreview(floating: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _ChoiceSection<NavigationContentStyle>(
                        title: '底栏内容',
                        selected: controller.navigationContentStyle.value,
                        onChanged: controller.setNavigationContentStyle,
                        options: const [
                          _AppearanceOption(
                            value: NavigationContentStyle.icons,
                            label: '仅图标',
                            preview: _BarContentPreview(
                              showIcons: true,
                              showLabels: false,
                            ),
                          ),
                          _AppearanceOption(
                            value: NavigationContentStyle.labels,
                            label: '仅文字',
                            preview: _BarContentPreview(
                              showIcons: false,
                              showLabels: true,
                            ),
                          ),
                          _AppearanceOption(
                            value: NavigationContentStyle.iconsAndLabels,
                            label: '图标和文字',
                            preview: _BarContentPreview(
                              showIcons: true,
                              showLabels: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          child: Text(title, style: Theme.of(context).textTheme.labelMedium),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpace.sm;
            final columnCount = options.length > 3 && constraints.maxWidth < 560
                ? 3
                : options.length;
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? colors.accent : colors.line,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            SizedBox(height: 54, child: Center(child: child)),
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
    final palette = AppColors.lightFor(tone);
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
  const _ThemePreview.light() : light = true, split = false;
  const _ThemePreview.dark() : light = false, split = false;
  const _ThemePreview.system() : light = true, split = true;

  final bool light;
  final bool split;

  @override
  Widget build(BuildContext context) {
    if (split) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeSwatch(light: true, half: true),
            _ThemeSwatch(light: false, half: true),
          ],
        ),
      );
    }
    return _ThemeSwatch(light: light);
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.light, this.half = false});

  final bool light;
  final bool half;

  @override
  Widget build(BuildContext context) {
    final palette = light ? AppColors.light : AppColors.dark;
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

class _BarShapePreview extends StatelessWidget {
  const _BarShapePreview({required this.floating});

  final bool floating;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 78,
      height: 48,
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.fromLTRB(floating ? 8 : 0, 0, floating ? 8 : 0, 5),
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: floating
              ? BorderRadius.circular(9)
              : const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}

class _BarContentPreview extends StatelessWidget {
  const _BarContentPreview({required this.showIcons, required this.showLabels});

  final bool showIcons;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 78,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var index = 0; index < 3; index++)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcons)
                  Icon(
                    index == 1
                        ? Icons.calendar_view_week_rounded
                        : Icons.circle_outlined,
                    size: 10,
                    color: index == 1 ? colors.accent : colors.inkFaint,
                  ),
                if (showIcons && showLabels) const SizedBox(height: 2),
                if (showLabels)
                  Container(
                    width: 13,
                    height: 3,
                    decoration: BoxDecoration(
                      color: index == 1 ? colors.accent : colors.inkFaint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
