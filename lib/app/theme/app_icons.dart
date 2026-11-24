import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// 普通功能统一用 Bold 线框，导航选中状态用 Fill 实心。
@staticIconProvider
abstract final class AppIcons {
  static const home = PhosphorIconsBold.house;
  static const homeFill = PhosphorIconsFill.house;
  static const calendar = PhosphorIconsBold.calendarDots;
  static const calendarFill = PhosphorIconsFill.calendarDots;
  static const user = PhosphorIconsBold.user;
  static const userFill = PhosphorIconsFill.user;
  static const arrowBack = PhosphorIconsBold.arrowLeft;
  static const arrowForward = PhosphorIconsBold.arrowRight;
  static const chevronRight = PhosphorIconsBold.caretRight;
  static const chevronDown = PhosphorIconsBold.caretDown;
  static const chevronUp = PhosphorIconsBold.caretUp;
  static const school = PhosphorIconsBold.graduationCap;
  static const clock = PhosphorIconsBold.clock;
  static const location = PhosphorIconsBold.mapPin;
  static const sun = PhosphorIconsBold.sun;
  static const sparkle = PhosphorIconsBold.sparkle;
  static const notifications = PhosphorIconsBold.bell;
  static const notificationsOff = PhosphorIconsBold.bellSlash;
  static const offline = PhosphorIconsBold.cloudSlash;
  static const palette = PhosphorIconsBold.palette;
  static const columns = PhosphorIconsBold.columns;
  static const rows = PhosphorIconsBold.rows;
  static const table = PhosphorIconsBold.table;
  static const upload = PhosphorIconsBold.fileArrowUp;
  static const code = PhosphorIconsBold.code;
  static const copy = PhosphorIconsBold.copy;
  static const check = PhosphorIconsBold.check;
  static const add = PhosphorIconsBold.plus;
  static const checkCircle = PhosphorIconsBold.checkCircle;
  static const refresh = PhosphorIconsBold.arrowsClockwise;
  static const search = PhosphorIconsBold.magnifyingGlass;
  static const swap = PhosphorIconsBold.arrowsLeftRight;
  static const settings = PhosphorIconsBold.slidersHorizontal;
  static const close = PhosphorIconsBold.x;
  static const edit = PhosphorIconsBold.pencilSimple;
  static const error = PhosphorIconsBold.warningCircle;
  static const info = PhosphorIconsBold.info;
  static const calendarCheck = PhosphorIconsBold.calendarCheck;
  static const textTop = PhosphorIconsBold.alignTopSimple;
  static const textCenter = PhosphorIconsBold.alignCenterVerticalSimple;
  static const textBottom = PhosphorIconsBold.alignBottomSimple;
  static const textSpacing = PhosphorIconsBold.arrowsVertical;
  static const windowMinimize = PhosphorIconsBold.minus;
  static const windowMaximize = PhosphorIconsBold.square;
  static const windowRestore = PhosphorIconsBold.copy;

  /// 头像可选图形，与 [AppIcons.avatarChoices] 的索引对应。
  static const star = PhosphorIconsBold.star;
  static const moon = PhosphorIconsBold.moon;
  static const coffee = PhosphorIconsBold.coffee;
  static const leaf = PhosphorIconsBold.leaf;
  static const book = PhosphorIconsBold.bookOpenText;
  static const heart = PhosphorIconsBold.heart;
  static const smile = PhosphorIconsBold.smiley;
  static const lightning = PhosphorIconsBold.lightning;

  /// 个人头像可选的图形，顺序即存储的索引。
  static const avatarChoices = <IconData>[
    user,
    school,
    book,
    star,
    leaf,
    coffee,
    moon,
    sparkle,
    smile,
    heart,
  ];

  /// 时间线的实心状态标记。
  static const statusDot = PhosphorIconsFill.circle;
}
