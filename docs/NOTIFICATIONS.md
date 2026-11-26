# 通知说明

本文件记录上课提醒、上课中的实时通知，以及小米 HyperOS「超级岛」焦点通知的接入依据。
应用本身离线工作，通知只在本机生成，不经过任何推送服务。

## 上课提醒

课前提醒使用 `flutter_local_notifications` 的定时通知，渠道 `class_reminder`，
按「上课提醒 / 考试提醒」各自的提前时间排期，修改设置后自动重排。

## 上课中的实时通知

原生侧（`android/app/src/main/kotlin/dev/qinghe/qinghe_app/MainActivity.kt`）
以常驻通知展示正在上的课，Dart 侧每 30 秒同步一次进度。

- **Android 16（API 36）及以上**：使用 `Notification.ProgressStyle`。
  - `setProgressSegments([Segment(total)])` 描述总时长，`setProgress(elapsed)` 给出当前进度；
  - `setStyledByProgress(false)` 让进度靠轨道图标（`setProgressTrackerIcon`）指示；
  - `setShortCriticalText(...)` 的内容显示在状态栏胶囊里；
  - 通知本身带 `FLAG_PROMOTED_ONGOING`，系统才会按实时通知处理（置顶、胶囊、锁屏）；
  - **展开通知**即可看到进度轨道与详情，另有一个「打开课表」操作。
- **低于 Android 16**：普通常驻通知 + `setProgress`，展开内容用 `BigTextStyle`
  展示课程、节次与地点。
- 点通知（或「打开课表」操作）会带 `qinghe_open=schedule` 回到应用，
  原生转给 Flutter 后切到课表页。

## 小米 HyperOS 焦点通知（超级岛）

HyperOS 的超级岛只读取 `miui.focus.*` 通知扩展，标准进度通知不会上岛。
公开协议要点：

- 载荷放在通知的 `miui.focus.param` 字符串里，**不超过 3072 字节**；
- 新版结构是 `param_v2`：`protocol`（3）、`business`（业务唯一标识）、`ticker`、
  `timeout`、`enableFloat`、`isShowNotification`、`baseInfo`（`type` / `title` /
  `content` / `picFunction` …）与 `param_island`（`bigIslandArea` / `smallIslandArea` /
  `islandTimeout`）；
- 图片通过 `miui.focus.pics` Bundle 提供，键名统一为 `miui.focus.pic_*`，
  JSON 中用 `picFunction` 引用；缺少这个 Bundle 时系统解析不到图片；
- 旧版 HyperOS 还会读顶层的 `miui.focus.businessId` / `miui.focus.ticker`，
  应用同时写入这两项以兼容。

> **授权前提**：小米只对已开通「焦点通知」权限的应用读取这些字段。
> 申请方式是向 `mipush-permission@xiaomi.com` 发邮件，主题形如
> `【申请开通小米焦点通知使用权限】-yymmdd-「应用名称」`，正文包含包名、应用信息、
> 使用场景与界面设计；授权一般按自然年计算。未授权时系统会忽略扩展字段，
> 应用仍正常显示普通通知。

应用在设置页「课程提醒 → 上课中的实时通知」里展示授权结果：原生通过
`content://miui.statusbar.notification.public` 的 `hasFocusPermission` 查询，
不是小米设备或未授权时按「未授权」展示，并说明需要向小米申请。

调试：

```powershell
adb shell am start -n dev.qinghe.qinghe_app/.MainActivity --es qinghe_preview_live 1
adb logcat -s QingheLive
```

日志会给出 `flags`、`canPostPromoted`、`focusPermission` 与设备厂商，便于判断
是系统能力不足还是权限未开通。

## 参考资料

- [Notification.ProgressStyle（Android Developers）](https://developer.android.com/reference/android/app/Notification.ProgressStyle)
- [Progress-centric notifications（Android 16）](https://developer.android.com/about/versions/16/features/progress-centric-notifications)
- [小米澎湃 OS 开发者平台：焦点通知常见问题](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2146)
- [小米澎湃 OS 开发者平台：开发指南](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2131)
- [阿里云 Push：Xiaomi Super Island 字段与限制](https://help.aliyun.com/en/document_detail/3037956.html)
- [HyperIsland-ToolKit：ParamV2 结构说明](https://hyperisland.d4viddf.com/docs/builder/)
