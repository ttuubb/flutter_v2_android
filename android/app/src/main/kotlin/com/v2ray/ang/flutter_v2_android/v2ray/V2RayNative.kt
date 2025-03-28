package com.v2ray.ang.flutter_v2_android.v2ray

import android.content.Context
import android.os.SystemClock
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.net.Socket
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * V2Ray 原生接口实现
 * 提供 V2Ray 核心的加载、初始化、启动和停止等功能
 */
class V2RayNative {
    companion object {
        private const val TAG = "V2RayNative"
        
        // 加载 V2Ray 核心库
        init {
            try {
                System.loadLibrary("v2ray")
                System.loadLibrary("v2raycore")
                Log.i(TAG, "V2Ray 核心库加载成功")
            } catch (e: Exception) {
                Log.e(TAG, "加载 V2Ray 核心库失败", e)
            }
        }
        
        // 单例实例
        private var INSTANCE: V2RayNative? = null
        
        // 获取单例实例
        @JvmStatic
        fun getInstance(): V2RayNative {
            if (INSTANCE == null) {
                synchronized(V2RayNative::class.java) {
                    if (INSTANCE == null) {
                        INSTANCE = V2RayNative()
                    }
                }
            }
            return INSTANCE!!
        }
    }
    
    // V2Ray 是否正在运行
    private var isRunning = false
    
    /**
     * 启动 V2Ray 服务
     * @param configContent V2Ray 配置内容（JSON格式）
     * @return 0 表示成功，其他值表示失败
     */
    fun start(configContent: String): Int {
        if (isRunning) {
            Log.w(TAG, "V2Ray 已经在运行")
            return 0
        }
        
        try {
            // 创建临时配置文件
            val configFile = createConfigFile(configContent)
            if (configFile == null) {
                Log.e(TAG, "创建配置文件失败")
                return -1
            }
            
            // 调用原生启动方法
            val result = startV2Ray(configFile.absolutePath)
            if (result == 0) {
                isRunning = true
                Log.i(TAG, "V2Ray 启动成功")
            } else {
                Log.e(TAG, "V2Ray 启动失败，错误码: $result")
            }
            
            return result
        } catch (e: Exception) {
            Log.e(TAG, "启动 V2Ray 时发生异常", e)
            return -2
        }
    }
    
    /**
     * 停止 V2Ray 服务
     */
    fun stop() {
        if (!isRunning) {
            Log.w(TAG, "V2Ray 未运行")
            return
        }
        
        try {
            // 调用原生停止方法
            stopV2Ray()
            isRunning = false
            Log.i(TAG, "V2Ray 已停止")
        } catch (e: Exception) {
            Log.e(TAG, "停止 V2Ray 时发生异常", e)
        }
    }
    
    /**
     * 获取 V2Ray 版本号
     * @return V2Ray 版本号
     */
    fun getVersion(): String {
        return try {
            val version = getV2RayVersion()
            Log.i(TAG, "V2Ray 版本: $version")
            version
        } catch (e: Exception) {
            Log.e(TAG, "获取 V2Ray 版本时发生异常", e)
            "unknown"
        }
    }
    
    /**
     * 测试服务器延迟
     * @param host 服务器地址
     * @param port 服务器端口
     * @param timeoutMs 超时时间（毫秒）
     * @return 延迟时间（毫秒），-1 表示测试失败
     */
    suspend fun testLatency(host: String, port: Int, timeoutMs: Int): Int = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "测试延迟: $host:$port")
            val socket = Socket()
            val startTime = SystemClock.elapsedRealtime()
            
            try {
                socket.connect(InetSocketAddress(host, port), timeoutMs)
                val latency = (SystemClock.elapsedRealtime() - startTime).toInt()
                Log.i(TAG, "延迟测试成功: ${latency}ms")
                latency
            } catch (e: Exception) {
                Log.e(TAG, "延迟测试失败", e)
                -1
            } finally {
                try {
                    socket.close()
                } catch (e: Exception) {
                    // 忽略关闭异常
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "测试延迟异常", e)
            -1
        }
    }
    
    /**
     * 创建临时配置文件
     * @param content 配置内容
     * @return 配置文件对象
     */
    private fun createConfigFile(content: String): File? {
        try {
            val configFile = File.createTempFile("v2ray", ".json")
            configFile.deleteOnExit()
            
            FileOutputStream(configFile).use { output ->
                output.write(content.toByteArray(Charsets.UTF_8))
                output.flush()
            }
            
            return configFile
        } catch (e: Exception) {
            Log.e(TAG, "创建配置文件时发生异常", e)
            return null
        }
    }
    
    /**
     * 原生方法：启动 V2Ray
     * @param configFilePath 配置文件路径
     * @return 0 表示成功，其他值表示失败
     */
    private external fun startV2Ray(configFilePath: String): Int
    
    /**
     * 原生方法：停止 V2Ray
     */
    private external fun stopV2Ray()
    
    /**
     * 原生方法：获取 V2Ray 版本
     * @return V2Ray 版本号
     */
    private external fun getV2RayVersion(): String
} 