package com.v2ray.ang.flutter_v2_android.v2ray

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.random.Random

/**
 * V2Ray Flutter 插件
 * 处理来自 Dart 层的方法调用，并转发到原生 V2Ray 实现
 */
class V2RayPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val TAG = "V2RayPlugin"
        private const val CHANNEL_NAME = "com.v2ray.ang.flutter_v2_android/v2ray"
    }
    
    // 方法通道
    private lateinit var channel: MethodChannel
    
    // 应用上下文
    private lateinit var context: Context
    
    // V2Ray 原生实现
    private val v2ray: V2RayNative by lazy { V2RayNative.getInstance() }
    
    // 协程作用域
    private val scope = CoroutineScope(Dispatchers.Main)
    
    /**
     * 插件绑定时调用
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        Log.i(TAG, "V2Ray 插件已绑定")
    }
    
    /**
     * 插件解绑时调用
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Log.i(TAG, "V2Ray 插件已解绑")
    }
    
    /**
     * 处理方法调用
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "收到方法调用: ${call.method}")
        
        scope.launch {
            try {
                when (call.method) {
                    "init" -> handleInit(result)
                    "start" -> handleStart(call, result)
                    "stop" -> handleStop(result)
                    "getVersion" -> handleGetVersion(result)
                    "testLatency" -> handleTestLatency(call, result)
                    "getStatsUp" -> handleGetStatsUp(result)
                    "getStatsDown" -> handleGetStatsDown(result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "处理方法调用异常: ${e.message}", e)
                result.error("NATIVE_ERROR", "处理方法调用异常: ${e.message}", e.stackTraceToString())
            }
        }
    }
    
    /**
     * 处理初始化请求
     */
    private fun handleInit(result: Result) {
        try {
            // 获取V2Ray版本
            val version = v2ray.getVersion()
            result.success(version)
            Log.i(TAG, "V2Ray初始化成功，版本: $version")
        } catch (e: Exception) {
            Log.e(TAG, "V2Ray初始化失败", e)
            result.error("INIT_ERROR", "V2Ray初始化失败: ${e.message}", null)
        }
    }
    
    /**
     * 处理启动V2Ray请求
     */
    private suspend fun handleStart(call: MethodCall, result: Result) = withContext(Dispatchers.IO) {
        try {
            // 获取配置内容
            val configContent = call.argument<String>("config")
            if (configContent.isNullOrBlank()) {
                result.error("CONFIG_ERROR", "配置内容为空", null)
                return@withContext
            }
            
            // 启动V2Ray
            val startResult = v2ray.start(configContent)
            if (startResult == 0) {
                // 启动成功，设置事件通道发送日志
                startLogEmitter()
                startStatsEmitter()
                result.success(true)
                Log.i(TAG, "V2Ray启动成功")
            } else {
                result.error("START_ERROR", "V2Ray启动失败，错误码: $startResult", null)
                Log.e(TAG, "V2Ray启动失败，错误码: $startResult")
            }
        } catch (e: Exception) {
            Log.e(TAG, "启动V2Ray异常", e)
            result.error("START_ERROR", "启动V2Ray异常: ${e.message}", null)
        }
    }
    
    /**
     * 处理停止V2Ray请求
     */
    private fun handleStop(result: Result) {
        try {
            // 停止V2Ray
            v2ray.stop()
            // 停止日志和统计数据发送
            stopLogEmitter()
            stopStatsEmitter()
            result.success(true)
            Log.i(TAG, "V2Ray停止成功")
        } catch (e: Exception) {
            Log.e(TAG, "停止V2Ray异常", e)
            result.error("STOP_ERROR", "停止V2Ray异常: ${e.message}", null)
        }
    }
    
    /**
     * 处理获取V2Ray版本请求
     */
    private fun handleGetVersion(result: Result) {
        try {
            val version = v2ray.getVersion()
            result.success(version)
            Log.i(TAG, "获取V2Ray版本成功: $version")
        } catch (e: Exception) {
            Log.e(TAG, "获取V2Ray版本异常", e)
            result.error("VERSION_ERROR", "获取V2Ray版本异常: ${e.message}", null)
        }
    }
    
    /**
     * 处理测试延迟请求
     */
    private suspend fun handleTestLatency(call: MethodCall, result: Result) = withContext(Dispatchers.IO) {
        try {
            val host = call.argument<String>("host") ?: return@withContext result.error("PARAM_ERROR", "未提供主机地址", null)
            val port = call.argument<Int>("port") ?: 443
            val timeout = call.argument<Int>("timeout") ?: 5000
            
            val latency = v2ray.testLatency(host, port, timeout)
            result.success(latency)
            Log.i(TAG, "测试延迟成功: ${latency}ms")
        } catch (e: Exception) {
            Log.e(TAG, "测试延迟异常", e)
            result.error("LATENCY_ERROR", "测试延迟异常: ${e.message}", null)
        }
    }
    
    /**
     * 处理获取上行流量统计
     */
    private fun handleGetStatsUp(result: Result) {
        try {
            // TODO: 实现从V2Ray获取上行流量统计
            // 临时返回随机数据作为示例
            result.success(Random.nextLong(1024, 10240))
        } catch (e: Exception) {
            Log.e(TAG, "获取上行流量统计异常", e)
            result.error("STATS_ERROR", "获取上行流量统计异常: ${e.message}", null)
        }
    }
    
    /**
     * 处理获取下行流量统计
     */
    private fun handleGetStatsDown(result: Result) {
        try {
            // TODO: 实现从V2Ray获取下行流量统计
            // 临时返回随机数据作为示例
            result.success(Random.nextLong(1024, 10240))
        } catch (e: Exception) {
            Log.e(TAG, "获取下行流量统计异常", e)
            result.error("STATS_ERROR", "获取下行流量统计异常: ${e.message}", null)
        }
    }
    
    // 用于发送日志的定时器
    private var logEmitterJob: Job? = null
    
    /**
     * 启动日志发送器
     */
    private fun startLogEmitter() {
        stopLogEmitter()
        
        logEmitterJob = scope.launch {
            while (isActive) {
                try {
                    // TODO: 实现从V2Ray获取日志
                    // 这里应该从V2Ray的日志输出中读取
                    val log = "V2Ray正在运行 - ${System.currentTimeMillis()}"
                    channel.invokeMethod("onLog", log)
                    delay(1000) // 每秒发送一次
                } catch (e: Exception) {
                    Log.e(TAG, "发送日志异常", e)
                }
            }
        }
    }
    
    /**
     * 停止日志发送器
     */
    private fun stopLogEmitter() {
        logEmitterJob?.cancel()
        logEmitterJob = null
    }
    
    // 用于发送流量统计的定时器
    private var statsEmitterJob: Job? = null
    
    /**
     * 启动流量统计发送器
     */
    private fun startStatsEmitter() {
        stopStatsEmitter()
        
        statsEmitterJob = scope.launch {
            var lastUpBytes = 0L
            var lastDownBytes = 0L
            var lastTime = System.currentTimeMillis()
            
            while (isActive) {
                try {
                    // TODO: 实现从V2Ray获取实际的流量统计
                    // 临时使用随机数据作为示例
                    val currentTime = System.currentTimeMillis()
                    val timeDiff = (currentTime - lastTime) / 1000.0
                    
                    // 模拟总流量（增长）
                    val upBytes = lastUpBytes + Random.nextLong(512, 2048)
                    val downBytes = lastDownBytes + Random.nextLong(1024, 4096)
                    
                    // 计算速率
                    val upSpeed = ((upBytes - lastUpBytes) / timeDiff).toLong()
                    val downSpeed = ((downBytes - lastDownBytes) / timeDiff).toLong()
                    
                    // 更新上次的值
                    lastUpBytes = upBytes
                    lastDownBytes = downBytes
                    lastTime = currentTime
                    
                    // 发送统计数据
                    val stats = mapOf(
                        "upSpeed" to upSpeed,
                        "downSpeed" to downSpeed,
                        "upTotal" to upBytes,
                        "downTotal" to downBytes
                    )
                    
                    channel.invokeMethod("onStats", stats)
                    delay(1000) // 每秒更新一次
                } catch (e: Exception) {
                    Log.e(TAG, "发送流量统计异常", e)
                }
            }
        }
    }
    
    /**
     * 停止流量统计发送器
     */
    private fun stopStatsEmitter() {
        statsEmitterJob?.cancel()
        statsEmitterJob = null
    }
} 