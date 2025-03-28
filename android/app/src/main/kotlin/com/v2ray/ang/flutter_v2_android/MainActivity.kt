package com.v2ray.ang.flutter_v2_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.v2ray.ang.flutter_v2_android.v2ray.V2RayPlugin
import com.v2ray.ang.flutter_v2_android.vpn.VpnPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 注册V2Ray插件
        flutterEngine.plugins.add(V2RayPlugin())
        // 注册VPN插件
        flutterEngine.plugins.add(VpnPlugin())
    }
}
