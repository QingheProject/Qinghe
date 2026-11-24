package dev.qinghe.qinghe_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 上课中的实时通知：Android 16 起用 `Notification.ProgressStyle`，
 * 状态栏胶囊与锁屏会把它当作进度型实时通知展示（各家「岛」也吃这类通知）。
 * 低版本退回带进度的常驻通知。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "dev.qinghe.qinghe_app/class_live"
    private val notificationId = 4201

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val title = call.argument<String>("title") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val shortText = call.argument<String>("shortText") ?: ""
                        val progress = (call.argument<Int>("progress") ?: 0).coerceAtLeast(0)
                        val max = (call.argument<Int>("max") ?: 100).coerceAtLeast(1)
                        val chipColor = call.argument<Long>("chipColor")
                        showLive(title, text, shortText, progress, max, chipColor)
                        result.success(null)
                    }
                    "cancel" -> {
                        notificationManager().cancel(notificationId)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // 实时通知用低重要度渠道：不上横幅、不响铃，只占状态栏与锁屏。
        val channel = NotificationChannel(
            CHANNEL_ID,
            "上课进行中",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "上课期间展示当前课程与进度"
            setShowBadge(false)
        }
        notificationManager().createNotificationChannel(channel)
    }

    private fun contentIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
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
        builder
            .setSmallIcon(android.R.drawable.ic_menu_my_calendar)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_PROGRESS)

        if (Build.VERSION.SDK_INT >= 36) {
            builder.setStyle(progressStyle(progress, max, chipColor))
            if (shortText.isNotEmpty()) {
                builder.setShortCriticalText(shortText)
            }
        } else {
            builder.setProgress(max, progress, false)
        }

        notificationManager().notify(notificationId, builder.build())
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
        const val CHANNEL_ID = "class_live"
    }
}
