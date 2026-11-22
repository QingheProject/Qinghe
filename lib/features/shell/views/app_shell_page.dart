import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/features/home/views/home_page.dart';
import 'package:qinghe_app/features/profile/views/profile_page.dart';
import 'package:qinghe_app/features/schedule/views/schedule_page.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';
import 'package:qinghe_app/features/shell/widgets/app_navigation.dart';

class AppShellPage extends GetView<ShellController> {
  const AppShellPage({super.key});

  static const _pages = <Widget>[HomePage(), SchedulePage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final appearance = Get.find<AppearanceController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 900;

        return Obx(() {
          final index = controller.currentIndex.value;
          final floating =
              appearance.bottomBarStyle.value == BottomBarStyle.floating;
          final contentStyle = appearance.navigationContentStyle.value;

          return Scaffold(
            backgroundColor: context.colors.canvas,
            extendBody: !useSideNavigation && floating,
            body: Row(
              children: [
                // 保持子组件位置固定，切换宽窄布局时页面状态不会重建。
                if (useSideNavigation)
                  AppSideRail(
                    selectedIndex: index,
                    onSelected: (value) => controller.selectSection(
                      value,
                      animate: !AppMotion.reduced(context),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    children: [
                      for (final page in _pages) _KeepAlive(child: page),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: useSideNavigation
                ? null
                : AppTabBar(
                    selectedIndex: index,
                    floating: floating,
                    contentStyle: contentStyle,
                    onSelected: (value) => controller.selectSection(
                      value,
                      animate: !AppMotion.reduced(context),
                    ),
                  ),
          );
        });
      },
    );
  }
}

/// 让滑出视口的页面保留状态，避免返回时重新播放进场动画。
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
