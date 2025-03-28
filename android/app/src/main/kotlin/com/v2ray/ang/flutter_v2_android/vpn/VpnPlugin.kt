package com.v2ray.ang.flutter_v2_android.vpn

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * VPN插件
 * 处理来自Dart层的VPN相关请求
 */
class VpnPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "VpnPlugin"
        private const val CHANNEL_NAME = "com.v2ray.flutter/vpn"
        private const val EVENT_CHANNEL_NAME = "com.v2ray.flutter/vpn/events"
        private const val REQUEST_VPN_PERMISSION = 1
        
        // 实际VPN服务类名
        private const val VPN_SERVICE_CLASS = "com.v2ray.ang.flutter_v2_android.vpn.V2rayVpnService"
    }
    
    // 方法通道
    private lateinit var channel: MethodChannel
    
    // 事件通道
    private lateinit var eventChannel: EventChannel
    
    // 应用上下文
    private lateinit var context: Context
    
    // 活动绑定
    private var activityBinding: ActivityPluginBinding? = null
    
    // VPN权限请求结果回调
    private var pendingPermissionResult: Result? = null
    
    // VPN当前状态
    private var vpnStatus: VpnStatus = VpnStatus.DISCONNECTED
    
    // 事件接收器
    private var eventSink: EventChannel.EventSink? = null
    
    // 协程作用域
    private val scope = CoroutineScope(Dispatchers.Main)
    
    // 状态检查任务
    private var statusCheckJob: Job? = null
    
    /**
     * 插件绑定时调用
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
        
        Log.i(TAG, "VPN插件已绑定")
    }
    
    /**
     * 插件解绑时调用
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
        Log.i(TAG, "VPN插件已解绑")
    }
    
    /**
     * 活动绑定时调用
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }
    
    /**
     * 活动重新绑定时调用
     */
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }
    
    /**
     * 活动解绑时调用
     */
    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }
    
    /**
     * 活动重新绑定配置变更时调用
     */
    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
    
    /**
     * 处理活动结果
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_VPN_PERMISSION) {
            val result = pendingPermissionResult
            pendingPermissionResult = null
            
            if (resultCode == android.app.Activity.RESULT_OK) {
                result?.success(true)
                return true
            } else {
                result?.success(false)
                return true
            }
        }
        return false
    }
    
    /**
     * 处理方法调用
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "收到方法调用: ${call.method}")
        
        try {
            when (call.method) {
                "init" -> handleInit(result)
                "getStatus" -> handleGetStatus(result)
                "start" -> handleStart(call, result)
                "stop" -> handleStop(result)
                "checkPermission" -> handleCheckPermission(result)
                "requestPermission" -> handleRequestPermission(result)
                "setDns" -> handleSetDns(call, result)
                "setRoutes" -> handleSetRoutes(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理方法调用异常: ${e.message}", e)
            result.error("NATIVE_ERROR", "处理方法调用异常: ${e.message}", e.stackTraceToString())
        }
    }
    
    /**
     * 处理初始化请求
     */
    private fun handleInit(result: Result) {
        try {
            // 启动状态检查任务
            startStatusCheck()
            // 检查VPN服务状态
            updateVpnStatus()
            
            result.success("VPN服务初始化成功")
            Log.i(TAG, "VPN服务初始化成功")
        } catch (e: Exception) {
            Log.e(TAG, "初始化VPN服务失败", e)
            result.error("INIT_ERROR", "初始化VPN服务失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理获取状态请求
     */
    private fun handleGetStatus(result: Result) {
        try {
            updateVpnStatus()
            result.success(vpnStatus.name)
            Log.d(TAG, "当前VPN状态: ${vpnStatus.name}")
        } catch (e: Exception) {
            Log.e(TAG, "获取VPN状态失败", e)
            result.error("STATUS_ERROR", "获取VPN状态失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理启动VPN请求
     */
    private fun handleStart(call: MethodCall, result: Result) {
        try {
            if (vpnStatus == VpnStatus.CONNECTED || vpnStatus == VpnStatus.CONNECTING) {
                Log.w(TAG, "VPN已在运行中")
                result.success(true)
                return
            }
            
            // 解析参数
            @Suppress("UNCHECKED_CAST")
            val params = call.arguments as? Map<String, Any> ?: run {
                result.error("PARAMS_ERROR", "参数格式错误", null)
                return
            }
            
            // 启动VPN之前先请求权限
            if (!isVpnPrepared()) {
                prepareVpn { prepared ->
                    if (prepared) {
                        doStartVpn(params, result)
                    } else {
                        Log.e(TAG, "VPN权限被拒绝")
                        result.success(false)
                    }
                }
            } else {
                doStartVpn(params, result)
            }
        } catch (e: Exception) {
            Log.e(TAG, "启动VPN失败", e)
            setVpnStatus(VpnStatus.ERROR)
            result.error("START_ERROR", "启动VPN失败: ${e.message}", null)
        }
    }
    
    /**
     * 实际启动VPN服务
     */
    private fun doStartVpn(params: Map<String, Any>, result: Result) {
        try {
            setVpnStatus(VpnStatus.CONNECTING)
            
            // 创建启动VPN服务的Intent
            val intent = Intent(context, Class.forName(VPN_SERVICE_CLASS))
            
            // 传递参数
            intent.putExtra("socksPort", params["socksPort"] as? Int ?: 1080)
            intent.putExtra("httpPort", params["httpPort"] as? Int ?: 1081)
            intent.putExtra("enableUdp", params["enableUdp"] as? Boolean ?: true)
            intent.putExtra("bypassLan", params["bypassLan"] as? Boolean ?: true)
            intent.putExtra("bypassChinese", params["bypassChinese"] as? Boolean ?: false)
            
            // 设置DNS
            @Suppress("UNCHECKED_CAST")
            val dns = params["dns"] as? List<String> ?: listOf("8.8.8.8", "8.8.4.4")
            intent.putExtra("dns", dns.toTypedArray())
            
            // 设置路由
            @Suppress("UNCHECKED_CAST")
            val routes = params["routes"] as? List<String> ?: listOf()
            intent.putExtra("routes", routes.toTypedArray())
            
            // 应用代理
            intent.putExtra("perAppProxy", params["perAppProxy"] as? Boolean ?: false)
            
            // 允许的应用
            @Suppress("UNCHECKED_CAST")
            val allowedApps = params["allowedApps"] as? List<String> ?: listOf()
            intent.putExtra("allowedApps", allowedApps.toTypedArray())
            
            // 启动服务
            context.startService(intent)
            
            // 设置一个延迟任务来检查VPN是否正常启动
            scope.launch {
                delay(1000) // 等待1秒钟
                updateVpnStatus()
                
                // 如果状态仍为CONNECTING，给更多时间
                if (vpnStatus == VpnStatus.CONNECTING) {
                    delay(2000) // 再等2秒
                    updateVpnStatus()
                }
                
                if (vpnStatus == VpnStatus.CONNECTED) {
                    Log.i(TAG, "VPN服务启动成功")
                } else if (vpnStatus != VpnStatus.CONNECTING) {
                    Log.e(TAG, "VPN服务启动失败，状态: $vpnStatus")
                }
            }
            
            result.success(true)
            Log.i(TAG, "已发送启动VPN服务请求")
        } catch (e: Exception) {
            Log.e(TAG, "启动VPN服务失败", e)
            setVpnStatus(VpnStatus.ERROR)
            result.success(false)
        }
    }
    
    /**
     * 处理停止VPN请求
     */
    private fun handleStop(result: Result) {
        try {
            if (vpnStatus == VpnStatus.DISCONNECTED || vpnStatus == VpnStatus.DISCONNECTING) {
                Log.w(TAG, "VPN已处于停止状态")
                result.success(true)
                return
            }
            
            setVpnStatus(VpnStatus.DISCONNECTING)
            
            // 创建停止VPN服务的Intent
            val intent = Intent(context, Class.forName(VPN_SERVICE_CLASS))
            intent.action = "STOP_VPN"
            context.startService(intent)
            
            // 设置一个延迟任务来检查VPN是否正常停止
            scope.launch {
                delay(1000) // 等待1秒钟
                updateVpnStatus()
                
                // 如果状态仍为DISCONNECTING，给更多时间
                if (vpnStatus == VpnStatus.DISCONNECTING) {
                    delay(2000) // 再等2秒
                    updateVpnStatus()
                }
                
                if (vpnStatus == VpnStatus.DISCONNECTED) {
                    Log.i(TAG, "VPN服务停止成功")
                } else if (vpnStatus != VpnStatus.DISCONNECTING) {
                    Log.e(TAG, "VPN服务停止失败，状态: $vpnStatus")
                }
            }
            
            result.success(true)
            Log.i(TAG, "已发送停止VPN服务请求")
        } catch (e: Exception) {
            Log.e(TAG, "停止VPN失败", e)
            setVpnStatus(VpnStatus.ERROR)
            result.error("STOP_ERROR", "停止VPN失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理检查VPN权限请求
     */
    private fun handleCheckPermission(result: Result) {
        try {
            val prepared = isVpnPrepared()
            result.success(prepared)
            Log.d(TAG, "VPN权限状态: ${if (prepared) "已授权" else "未授权"}")
        } catch (e: Exception) {
            Log.e(TAG, "检查VPN权限失败", e)
            result.error("PERMISSION_ERROR", "检查VPN权限失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理请求VPN权限
     */
    private fun handleRequestPermission(result: Result) {
        try {
            if (isVpnPrepared()) {
                Log.d(TAG, "VPN已有权限")
                result.success(true)
                return
            }
            
            prepareVpn { prepared ->
                result.success(prepared)
                Log.d(TAG, "VPN权限请求结果: ${if (prepared) "已授权" else "未授权"}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "请求VPN权限失败", e)
            result.error("PERMISSION_ERROR", "请求VPN权限失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理设置DNS请求
     */
    private fun handleSetDns(call: MethodCall, result: Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val dns = call.argument<Map<String, Any>>("dns")?.get("dns") as? List<String> ?: run {
                result.error("PARAMS_ERROR", "缺少DNS参数", null)
                return
            }
            
            // 创建设置DNS的Intent
            val intent = Intent(context, Class.forName(VPN_SERVICE_CLASS))
            intent.action = "UPDATE_DNS"
            intent.putExtra("dns", dns.toTypedArray())
            context.startService(intent)
            
            result.success(true)
            Log.d(TAG, "设置DNS成功: $dns")
        } catch (e: Exception) {
            Log.e(TAG, "设置DNS失败", e)
            result.error("DNS_ERROR", "设置DNS失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理设置路由请求
     */
    private fun handleSetRoutes(call: MethodCall, result: Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val routes = call.argument<Map<String, Any>>("routes")?.get("routes") as? List<String> ?: run {
                result.error("PARAMS_ERROR", "缺少路由参数", null)
                return
            }
            
            // 创建设置路由的Intent
            val intent = Intent(context, Class.forName(VPN_SERVICE_CLASS))
            intent.action = "UPDATE_ROUTES"
            intent.putExtra("routes", routes.toTypedArray())
            context.startService(intent)
            
            result.success(true)
            Log.d(TAG, "设置路由成功: $routes")
        } catch (e: Exception) {
            Log.e(TAG, "设置路由失败", e)
            result.error("ROUTES_ERROR", "设置路由失败: ${e.message}", null)
        }
    }
    
    /**
     * 准备VPN（请求权限）
     */
    private fun prepareVpn(callback: (Boolean) -> Unit) {
        val activity = activityBinding?.activity ?: run {
            Log.e(TAG, "活动不可用")
            callback(false)
            return
        }
        
        val intent = VpnService.prepare(context)
        if (intent == null) {
            // 已经有权限
            callback(true)
            return
        }
        
        try {
            pendingPermissionResult = object : Result {
                override fun success(result: Any?) {
                    callback(result as? Boolean ?: false)
                }
                
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "VPN权限请求错误: $errorMessage")
                    callback(false)
                }
                
                override fun notImplemented() {
                    Log.e(TAG, "VPN权限请求方法未实现")
                    callback(false)
                }
            }
            
            activity.startActivityForResult(intent, REQUEST_VPN_PERMISSION)
        } catch (e: Exception) {
            Log.e(TAG, "请求VPN权限失败", e)
            callback(false)
        }
    }
    
    /**
     * 检查VPN是否已准备
     */
    private fun isVpnPrepared(): Boolean {
        return VpnService.prepare(context) == null
    }
    
    /**
     * 更新VPN状态
     */
    private fun updateVpnStatus() {
        try {
            // 这里应该从VPN服务中获取实际状态
            // 这里使用广播接收器或服务绑定从V2rayVpnService获取状态
            // 暂时使用模拟状态
            // TODO: 实现从服务获取真实状态
            
            // 判断VPN服务是否正在运行
            val serviceRunning = VpnStatusMonitor.isVpnServiceRunning(context, VPN_SERVICE_CLASS)
            
            if (serviceRunning) {
                // 服务正在运行，但可能处于各种状态
                val status = VpnStatusMonitor.getVpnStatus()
                setVpnStatus(status)
            } else {
                // 服务未运行
                setVpnStatus(VpnStatus.DISCONNECTED)
            }
        } catch (e: Exception) {
            Log.e(TAG, "更新VPN状态失败", e)
        }
    }
    
    /**
     * 启动状态检查任务
     */
    private fun startStatusCheck() {
        stopStatusCheck()
        
        statusCheckJob = scope.launch {
            while (true) {
                try {
                    updateVpnStatus()
                    delay(1000) // 每秒检查一次
                } catch (e: Exception) {
                    Log.e(TAG, "状态检查异常", e)
                }
            }
        }
    }
    
    /**
     * 停止状态检查任务
     */
    private fun stopStatusCheck() {
        statusCheckJob?.cancel()
        statusCheckJob = null
    }
    
    /**
     * 设置VPN状态并通知Dart层
     */
    private fun setVpnStatus(status: VpnStatus) {
        if (vpnStatus != status) {
            vpnStatus = status
            
            // 通过事件通道通知状态变化
            try {
                eventSink?.success(status.name)
            } catch (e: Exception) {
                Log.e(TAG, "通知状态变化失败", e)
            }
        }
    }
    
    /**
     * 事件流打开时调用
     */
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "状态事件监听已开始")
    }
    
    /**
     * 事件流取消时调用
     */
    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "状态事件监听已取消")
    }
}

/**
 * VPN状态枚举
 */
enum class VpnStatus {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR
}

/**
 * VPN状态监视器
 * 用于跟踪VPN服务状态
 */
object VpnStatusMonitor {
    private var currentStatus: VpnStatus = VpnStatus.DISCONNECTED
    
    /**
     * 设置VPN状态
     */
    fun setVpnStatus(status: VpnStatus) {
        currentStatus = status
    }
    
    /**
     * 获取VPN状态
     */
    fun getVpnStatus(): VpnStatus {
        return currentStatus
    }
    
    /**
     * 判断VPN服务是否在运行
     */
    fun isVpnServiceRunning(context: Context, serviceClassName: String): Boolean {
        try {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
                if (serviceClassName == service.service.className) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e("VpnStatusMonitor", "检查服务运行状态失败", e)
        }
        return false
    }
} 