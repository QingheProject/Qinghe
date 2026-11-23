import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;

  /// 三个主页面左右排列，可直接滑动切换。
  final pageController = PageController();
  Object? _activeSelection;

  /// 切换目标时中断当前横移动画，以最近一次选择为准。
  Future<void> selectSection(int index, {bool animate = true}) async {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    if (!pageController.hasClients) return;
    if (!animate) {
      _activeSelection = null;
      pageController.jumpToPage(index);
      return;
    }

    final selection = Object();
    _activeSelection = selection;
    try {
      await pageController.animateToPage(
        index,
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
      );
    } finally {
      if (identical(_activeSelection, selection)) {
        _activeSelection = null;
        // 用户手势也能中断横移，选中项以此时可见的页面为准。
        final page = pageController.hasClients ? pageController.page : null;
        if (page != null) currentIndex.value = page.round();
      }
    }
  }

  /// 左右滑动越过一半时同步选中项。
  void onPageChanged(int index) {
    if (_activeSelection == null) currentIndex.value = index;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
