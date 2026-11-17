package io.github.sakuracake.amap_native

import android.content.Context
import android.view.Gravity
import android.view.View
import android.widget.TextView
import androidx.lifecycle.Lifecycle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Base-SDK navigation stub. It keeps the Dart API complete without linking the
 * ~71 MB AMap navigation native library into apps that do not need it.
 *
 * Build with `-PamapNativeNavi=true` to switch to the navi SDK implementation.
 */
class AmapNaviViewFactory(
    private val messenger: BinaryMessenger,
    @Suppress("UNUSED_PARAMETER") lifecycleProvider: () -> Lifecycle?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        AmapNaviPlatformView(context, messenger, viewId)
}

class AmapNaviPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int
) : PlatformView, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val view = TextView(context).apply {
        text = "导航 SDK 未启用。请使用 -PamapNativeNavi=true 构建。"
        gravity = Gravity.CENTER
        setPadding(32, 32, 32, 32)
    }
    private val channel = MethodChannel(messenger, "amap_native/navi/$viewId")
    private val eventChannel = EventChannel(messenger, "amap_native/navi/$viewId/events")

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun getView(): View = view

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.error(
            "navi_unavailable",
            "AMap navigation is not included in this build. Rebuild with -PamapNativeNavi=true.",
            null
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        events?.error(
            "navi_unavailable",
            "AMap navigation is not included in this build.",
            null
        )
    }

    override fun onCancel(arguments: Any?) = Unit

    override fun dispose() {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
