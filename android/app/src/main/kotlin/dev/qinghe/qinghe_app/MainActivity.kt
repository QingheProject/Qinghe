package dev.qinghe.qinghe_app

import android.app.Notification
import android.app.Notification.Action
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * 上课中的实时通知。
 *
 * - Android 16（API 36）起使用 `Notification.ProgressStyle`：通知栏置顶、
 *   状态栏胶囊与锁屏都按进度型实时通知展示，展开后是一段进度轨道。
 * - 低版本退回带进度的常驻通知，展开内容用 BigTextStyle 补全课程详情。
 * - 小米 HyperOS 的超级岛/焦点通知只读 `miui.focus.*` 扩展字段，这里按公开协议
 *   写入 `param_v2` 载荷；是否真正上岛取决于应用是否已获得小米焦点通知权限。
 *
 * 相关说明见 docs/NOTIFICATIONS.md。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "dev.qinghe.qinghe_app/class_live"
    private val notificationId = 4201
    private var channel: MethodChannel? = null
    private var pendingOpenRoute: String? = null
    private var lastPreviewAt = 0L

    private var focusBitmapCache: Bitmap? = null
    private var focusPicBase64: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "show" -> {
                            val title = call.argument<String>("title") ?: ""
                            val text = call.argument<String>("text") ?: ""
                            val shortText = call.argument<String>("shortText") ?: ""
                            val detail = call.argument<String>("detail") ?: ""
                            val progress = (call.argument<Int>("progress") ?: 0).coerceAtLeast(0)
                            val max = (call.argument<Int>("max") ?: 100).coerceAtLeast(1)
                            val chipColor = call.argument<Long>("chipColor")
                            showLive(title, text, shortText, detail, progress, max, chipColor)
                            result.success(null)
                        }
                        "cancel" -> {
                            notificationManager().cancel(notificationId)
                            result.success(null)
                        }
                        "canPromote" -> {
                            val can = if (Build.VERSION.SDK_INT >= 36) {
                                notificationManager().canPostPromotedNotifications()
                            } else {
                                false
                            }
                            result.success(can)
                        }
                        "status" -> result.success(status())
                        else -> result.notImplemented()
                    }
                }
            }
        pendingOpenRoute?.let { route ->
            pendingOpenRoute = null
            channel?.invokeMethod("opened", route)
        }
    }

    /** 小米焦点通知权限、系统版本与厂商，供设置页展示。 */
    private fun status(): Map<String, Any?> = mapOf(
        "manufacturer" to Build.MANUFACTURER,
        "brand" to Build.BRAND,
        "sdk" to Build.VERSION.SDK_INT,
        "focusPermission" to hasFocusPermission(),
        "canPromote" to (Build.VERSION.SDK_INT >= 36 &&
            notificationManager().canPostPromotedNotifications()),
    )

    /**
     * 查询小米焦点通知（超级岛）权限。
     *
     * HyperOS 通过系统 ContentProvider 暴露授权结果；未授权或不是小米系统时
     * 调用会失败，按未授权处理即可。
     */
    private fun hasFocusPermission(): Boolean {
        val authority = Uri.parse("content://miui.statusbar.notification.public")
        return try {
            val bundle = contentResolver.call(authority, "hasFocusPermission", null, null)
            bundle?.getBoolean("hasFocusPermission", false) ?: false
        } catch (error: Throwable) {
            false
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handlePreviewIntent(intent)
        handleOpenIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handlePreviewIntent(intent)
        handleOpenIntent(intent)
    }

    /**
     * 调试入口：`adb shell am start ... --es qinghe_preview_live 1`
     * 在不点屏幕的情况下验证实时通知 / 焦点通知的效果；用后即清除，避免重复弹出。
     */
    private fun handlePreviewIntent(intent: Intent?) {
        if (intent?.getStringExtra(EXTRA_PREVIEW) != "1") return
        intent.removeExtra(EXTRA_PREVIEW)
        // onNewIntent 与 onResume 可能先后拿到同一个 intent，两秒内只弹一次。
        val now = System.currentTimeMillis()
        if (now - lastPreviewAt < 2000) return
        lastPreviewAt = now
        showLive("示例课程", "还剩 30 分钟", "剩 30 分钟", "第 3–4 节 · 东 1208", 15, 45, null)
    }

    /** 点通知进来时，把目标页面交给 Flutter 侧处理。 */
    private fun handleOpenIntent(intent: Intent?) {
        val route = intent?.getStringExtra(EXTRA_OPEN) ?: return
        intent.removeExtra(EXTRA_OPEN)
        val target = channel
        if (target == null) {
            pendingOpenRoute = route
        } else {
            target.invokeMethod("opened", route)
        }
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // 实时通知要能「上岛」，渠道重要度必须是 DEFAULT 或更高；
        // 用新 id 是因为渠道建好之后重要度改不了。
        val notificationChannel = NotificationChannel(
            CHANNEL_ID,
            "上课进行中",
            // 小米 HyperOS 会拦截低优先级通知，实时通知用 HIGH 才能在通知栏出现；
            // 渠道本身不响铃不振动，不会打扰。
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "上课期间展示当前课程与进度，可在通知栏展开、状态栏胶囊与锁屏上看到"
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        notificationManager().createNotificationChannel(notificationChannel)
    }

    private fun contentIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN, "schedule")
        }
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun showLive(
        title: String,
        text: String,
        shortText: String,
        detail: String,
        progress: Int,
        max: Int,
        chipColor: Long?,
    ) {
        ensureChannel()
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val pendingIntent = contentIntent()
        builder
            .setSmallIcon(android.R.drawable.ic_menu_my_calendar)
            .setContentTitle(title)
            .setContentText(text)
            .setSubText("青禾 · 上课中")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
            .setCategory(Notification.CATEGORY_PROGRESS)
            // 展开后可以直接打开课表。
            .addAction(openScheduleAction(pendingIntent))

        if (Build.VERSION.SDK_INT >= 36) {
            // 展开后是一段进度轨道；胶囊里显示 shortText。
            builder.setStyle(progressStyle(progress, max, chipColor))
            if (shortText.isNotEmpty()) {
                builder.setShortCriticalText(shortText)
            }
        } else {
            @Suppress("DEPRECATION")
            builder.setStyle(
                Notification.BigTextStyle()
                    .setBigContentTitle(title)
                    .setSummaryText("上课中")
                    .bigText(listOf(text, detail).filter { it.isNotEmpty() }.joinToString("\n")),
            )
            builder.setProgress(max, progress, false)
        }

        val notification = builder.build()
        if (Build.VERSION.SDK_INT >= 36) {
            // Android 16 的「晋升为实时通知」标记：状态栏胶囊靠它。
            // 平台没有公开的 builder 方法，直接置标记位（NotificationCompat 内部也是这么做的）。
            notification.flags = notification.flags or Notification.FLAG_PROMOTED_ONGOING
        }
        applyFocusExtras(notification, title, text, shortText, detail)

        android.util.Log.i(
            LOG_TAG,
            "notify flags=0x" + notification.flags.toString(16) +
                " canPostPromoted=" +
                (Build.VERSION.SDK_INT >= 36 && notificationManager().canPostPromotedNotifications()) +
                " focusPermission=${hasFocusPermission()}" +
                " device=${Build.MANUFACTURER}/${Build.BRAND}",
        )
        notificationManager().notify(notificationId, notification)
    }

    private fun openScheduleAction(pendingIntent: PendingIntent): Action {
        val icon = android.graphics.drawable.Icon.createWithResource(
            this,
            android.R.drawable.ic_menu_agenda,
        )
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Action.Builder(icon, "打开课表", pendingIntent).build()
        } else {
            @Suppress("DEPRECATION")
            Action.Builder(android.R.drawable.ic_menu_agenda, "打开课表", pendingIntent).build()
        }
    }

    /**
     * 小米焦点通知（超级岛）扩展。
     *
     * 公开协议：`miui.focus.param` 里放 `param_v2` JSON，图片通过
     * `miui.focus.pics` Bundle 以 `miui.focus.pic_*` 为键提供。
     * 只有应用获得小米焦点通知权限后，系统才会读取这些字段；
     * 未授权时系统按普通通知处理，不影响其他功能。
     */
    private fun applyFocusExtras(
        notification: Notification,
        title: String,
        text: String,
        shortText: String,
        detail: String,
    ) {
        try {
            val extras = notification.extras ?: return
            val ticker = if (shortText.isNotEmpty()) shortText else text
            val content = if (detail.isNotEmpty()) "$text · $detail" else text

            val baseInfo = JSONObject().apply {
                put("type", 1)
                put("title", title)
                put("content", content)
                put("picFunction", PIC_TICKER)
            }
            val island = JSONObject().apply {
                put("islandTimeout", 3600)
                put("bigIslandArea", JSONObject().apply {
                    put("iconTextInfo", JSONObject().apply {
                        put("pic", PIC_TICKER)
                        put("title", title)
                        put("content", ticker)
                    })
                })
                put("smallIslandArea", JSONObject().apply {
                    put("iconInfo", JSONObject().apply { put("pic", PIC_TICKER) })
                })
            }
            val paramV2 = JSONObject().apply {
                put("protocol", 3)
                put("business", FOCUS_BUSINESS_ID)
                put("ticker", ticker)
                put("enableFloat", true)
                put("isShowNotification", true)
                put("islandFirstFloat", false)
                put("timeout", 0)
                put("baseInfo", baseInfo)
                put("param_island", island)
            }
            val payload = JSONObject().apply {
                put("isShowNotification", true)
                put("param_v2", paramV2)
            }
            val json = payload.toString()
            extras.putString("miui.focus.param", json)
            // 旧版 HyperOS 仍读这几个顶层字段，一并写入。
            extras.putString("miui.focus.businessId", FOCUS_BUSINESS_ID)
            extras.putString("miui.focus.ticker", ticker)

            focusBitmap()?.let { bitmap ->
                val pics = Bundle().apply { putParcelable(PIC_TICKER, bitmap) }
                extras.putBundle("miui.focus.pics", pics)
            }
            if (json.toByteArray().size > FOCUS_PARAM_LIMIT) {
                android.util.Log.w(LOG_TAG, "focus param exceeds ${FOCUS_PARAM_LIMIT}B")
            }
        } catch (error: Throwable) {
            android.util.Log.w(LOG_TAG, "focus extras skipped: " + error.message)
        }
    }

    private fun focusBitmap(): Bitmap? = focusBitmapCache ?: run {
        val drawable = try {
            androidx.core.content.ContextCompat.getDrawable(
                this,
                android.R.drawable.ic_menu_my_calendar,
            ) ?: return null
        } catch (error: Throwable) {
            return null
        }
        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 96
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        focusBitmapCache = bitmap
        bitmap
    }

    /**
     * Android 16 的进度样式：胶囊里显示 [shortText]，展开后按分段进度展示。
     *
     * 进度模型是「分段 + 当前进度」：段长之和是总量，[progress] 落在段内，
     * 系统据此算出百分比。
     */
    @RequiresApi(36)
    private fun progressStyle(
        progress: Int,
        max: Int,
        chipColor: Long?,
    ): Notification.ProgressStyle {
        val total = max.coerceAtLeast(1)
        val current = progress.coerceIn(0, total)
        val segment = Notification.ProgressStyle.Segment(total)
        if (chipColor != null) {
            segment.setColor(chipColor.toInt())
        }
        return Notification.ProgressStyle()
            // 保留未走完部分的分段样式，靠上方的轨迹图标指出当前进度。
            .setStyledByProgress(false)
            .setProgress(current)
            .setProgressSegments(listOf(segment))
            .setProgressTrackerIcon(
                android.graphics.drawable.Icon.createWithResource(
                    this,
                    android.R.drawable.ic_menu_my_calendar,
                ),
            )
    }

    private companion object {
        const val CHANNEL_ID = "class_live_v3"
        const val LOG_TAG = "QingheLive"
        const val FOCUS_BUSINESS_ID = "qinghe_class_live"
        const val PIC_TICKER = "miui.focus.pic_ticker"
        const val FOCUS_PARAM_LIMIT = 3072
        const val EXTRA_OPEN = "qinghe_open"
        const val EXTRA_PREVIEW = "qinghe_preview_live"
    }
}
