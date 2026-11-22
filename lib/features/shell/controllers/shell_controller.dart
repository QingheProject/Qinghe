import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;

  /// 三个主页面左右排列，可直接滑动切换。
  final pageController = PageController();
  int? _targetIndex;

  /// 点击导航：用可中断的横向动画切换页面，并忽略动画期间的重复点击。
  Future<void> selectSection(int index, {bool animate = true}) async {
    if (currentIndex.value == index || _targetIndex != null) return;
    currentIndex.value = index;
    if (!pageController.hasClients) return;
    if (!animate) {
      pageController.jumpToPage(index);
      return;
    }

    _targetIndex = index;
    try {
      await pageController.animateToPage(
        index,
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
      );
    } finally {
      currentIndex.value = index;
      _targetIndex = null;
    }
  }

  /// 左右滑动越过一半时同步选中项。
  void onPageChanged(int index) {
    if (_targetIndex == null) currentIndex.value = index;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
