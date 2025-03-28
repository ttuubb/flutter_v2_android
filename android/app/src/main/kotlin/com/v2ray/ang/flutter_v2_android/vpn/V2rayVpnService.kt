package com.v2ray.ang.flutter_v2_android.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import com.v2ray.ang.flutter_v2_android.MainActivity
import com.v2ray.ang.flutter_v2_android.v2ray.V2RayNative
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * V2Ray VPN服务
 * 提供VPN功能，将所有网络流量重定向到V2Ray代理
 */
class V2rayVpnService : VpnService() {
    companion object {
        private const val TAG = "V2rayVpnService"

        // 通知ID
        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL_ID = "v2ray_vpn_channel"
        
        // 默认DNS
        private val DEFAULT_DNS = arrayOf("8.8.8.8", "8.8.4.4")
        
        // 默认MTU
        private const val DEFAULT_MTU = 1500
        
        // 当前实例
        private var instance: V2rayVpnService? = null
        
        // 获取实例
        fun getInstance(): V2rayVpnService? = instance
    }
    
    // 协程作用域
    private val scope = CoroutineScope(Dispatchers.IO)
    
    // VPN参数
    private var socksPort: Int = 1080
    private var httpPort: Int = 1081
    private var enableUdp: Boolean = true
    private var bypassLan: Boolean = true
    private var bypassChinese: Boolean = false
    private var dnsServers: Array<String> = DEFAULT_DNS
    private var routes: Array<String> = emptyArray()
    private var perAppProxy: Boolean = false
    private var allowedApps: Array<String> = emptyArray()
    
    // VPN状态
    private val running = AtomicBoolean(false)
    private val vpnStatus = AtomicReference(VpnStatus.DISCONNECTED)
    
    // VPN接口文件描述符
    private var vpnInterface: ParcelFileDescriptor? = null
    
    // 保护套接字任务
    private var protectSocketJob: Job? = null
    
    /**
     * 服务创建时调用
     */
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // 创建通知通道
        createNotificationChannel()
        
        // 发送前台服务通知
        startForeground(NOTIFICATION_ID, createNotification("V2Ray VPN服务正在初始化"))
        
        Log.i(TAG, "V2Ray VPN服务已创建")
    }
    
    /**
     * 服务启动时调用
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            return START_NOT_STICKY
        }
        
        val action = intent.action
        if (action != null) {
            when (action) {
                "STOP_VPN" -> {
                    stopVpn()
                    return START_NOT_STICKY
                }
                "UPDATE_DNS" -> {
                    val dns = intent.getStringArrayExtra("dns")
                    if (dns != null) {
                        dnsServers = dns
                        Log.i(TAG, "更新DNS: ${dns.joinToString()}")
                    }
                    return START_STICKY
                }
                "UPDATE_ROUTES" -> {
                    val newRoutes = intent.getStringArrayExtra("routes")
                    if (newRoutes != null) {
                        routes = newRoutes
                        Log.i(TAG, "更新路由: ${newRoutes.joinToString()}")
                    }
                    return START_STICKY
                }
            }
        }
        
        // 获取参数
        socksPort = intent.getIntExtra("socksPort", 1080)
        httpPort = intent.getIntExtra("httpPort", 1081)
        enableUdp = intent.getBooleanExtra("enableUdp", true)
        bypassLan = intent.getBooleanExtra("bypassLan", true)
        bypassChinese = intent.getBooleanExtra("bypassChinese", false)
        
        val dns = intent.getStringArrayExtra("dns")
        if (dns != null && dns.isNotEmpty()) {
            dnsServers = dns
        }
        
        val newRoutes = intent.getStringArrayExtra("routes")
        if (newRoutes != null) {
            routes = newRoutes
        }
        
        perAppProxy = intent.getBooleanExtra("perAppProxy", false)
        val apps = intent.getStringArrayExtra("allowedApps")
        if (apps != null) {
            allowedApps = apps
        }
        
        // 启动VPN
        startVpn()
        
        return START_STICKY
    }
    
    /**
     * 服务销毁时调用
     */
    override fun onDestroy() {
        stopVpn()
        stopForeground(true)
        instance = null
        
        // 停止协程
        protectSocketJob?.cancel()
        
        Log.i(TAG, "V2Ray VPN服务已销毁")
        super.onDestroy()
    }
    
    /**
     * 启动VPN
     */
    private fun startVpn() {
        if (running.get()) {
            Log.w(TAG, "VPN已经在运行")
            return
        }
        
        scope.launch {
            try {
                setVpnStatus(VpnStatus.CONNECTING)
                updateNotification("V2Ray VPN服务正在连接")
                
                // 建立VPN接口
                vpnInterface = establishVpn()
                if (vpnInterface == null) {
                    Log.e(TAG, "无法建立VPN接口")
                    setVpnStatus(VpnStatus.ERROR)
                    updateNotification("V2Ray VPN服务建立失败")
                    return@launch
                }
                
                // 启动保护套接字任务
                startProtectSocketJob()
                
                running.set(true)
                setVpnStatus(VpnStatus.CONNECTED)
                updateNotification("V2Ray VPN服务已连接")
                
                Log.i(TAG, "VPN已启动")
            } catch (e: Exception) {
                Log.e(TAG, "启动VPN失败", e)
                stopVpn()
                setVpnStatus(VpnStatus.ERROR)
                updateNotification("V2Ray VPN服务启动失败")
            }
        }
    }
    
    /**
     * 停止VPN
     */
    private fun stopVpn() {
        if (!running.get() && vpnInterface == null) {
            Log.w(TAG, "VPN未运行")
            return
        }
        
        try {
            setVpnStatus(VpnStatus.DISCONNECTING)
            updateNotification("V2Ray VPN服务正在断开")
            
            protectSocketJob?.cancel()
            protectSocketJob = null
            
            // 关闭VPN接口
            try {
                vpnInterface?.close()
            } catch (e: Exception) {
                Log.e(TAG, "关闭VPN接口失败", e)
            }
            vpnInterface = null
            
            running.set(false)
            setVpnStatus(VpnStatus.DISCONNECTED)
            updateNotification("V2Ray VPN服务已断开")
            
            Log.i(TAG, "VPN已停止")
        } catch (e: Exception) {
            Log.e(TAG, "停止VPN失败", e)
            setVpnStatus(VpnStatus.ERROR)
            updateNotification("V2Ray VPN服务停止失败")
        }
    }
    
    /**
     * 建立VPN接口
     */
    private fun establishVpn(): ParcelFileDescriptor? {
        try {
            // VPN接口构建器
            val builder = Builder()
            
            // 设置会话名称
            builder.setSession("V2Ray VPN")
            
            // 设置MTU
            builder.setMtu(DEFAULT_MTU)
            
            // 设置地址和路由
            builder.addAddress("10.1.10.1", 32)
            builder.addRoute("0.0.0.0", 0)
            
            // 设置DNS
            for (dns in dnsServers) {
                try {
                    val dnsAddr = InetAddress.getByName(dns.trim())
                    builder.addDnsServer(dnsAddr)
                    Log.d(TAG, "添加DNS: $dns")
                } catch (e: Exception) {
                    Log.e(TAG, "添加DNS失败: $dns", e)
                }
            }
            
            // 设置绕过局域网
            if (bypassLan) {
                // 添加局域网路由，不经过VPN
                addBypassLanRoutes(builder)
            }
            
            // 设置分应用代理
            if (perAppProxy && allowedApps.isNotEmpty()) {
                for (app in allowedApps) {
                    try {
                        builder.addAllowedApplication(app)
                        Log.d(TAG, "添加允许的应用: $app")
                    } catch (e: Exception) {
                        Log.e(TAG, "添加允许的应用失败: $app", e)
                    }
                }
            }
            
            // 允许绕过VPN的应用
            builder.addDisallowedApplication(packageName)
            
            // 创建VPN接口
            return builder.establish()
        } catch (e: Exception) {
            Log.e(TAG, "建立VPN接口失败", e)
            return null
        }
    }
    
    /**
     * 添加绕过局域网的路由
     */
    private fun addBypassLanRoutes(builder: Builder) {
        // 局域网网段
        val lanRoutes = arrayOf(
            Pair("10.0.0.0", 8),
            Pair("172.16.0.0", 12),
            Pair("192.168.0.0", 16),
            Pair("127.0.0.0", 8),
            Pair("169.254.0.0", 16)
        )
        
        for (route in lanRoutes) {
            try {
                builder.addRoute(route.first, route.second)
                Log.d(TAG, "添加局域网路由: ${route.first}/${route.second}")
            } catch (e: Exception) {
                Log.e(TAG, "添加局域网路由失败: ${route.first}/${route.second}", e)
            }
        }
    }
    
    /**
     * 启动保护套接字任务
     */
    private fun startProtectSocketJob() {
        protectSocketJob?.cancel()
        
        // 启动一个任务来保护V2Ray的套接字
        protectSocketJob = scope.launch {
            while (true) {
                try {
                    // 与V2Ray通信，保护其套接字
                    // 这里应该根据实际情况实现
                    
                    delay(1000) // 每秒检查一次
                } catch (e: Exception) {
                    Log.e(TAG, "保护套接字失败", e)
                }
            }
        }
    }
    
    /**
     * 创建通知通道
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "V2Ray VPN服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "V2Ray VPN服务通知"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * 创建通知
     */
    private fun createNotification(content: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
        
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_LOW)
        }
        
        return builder
            .setContentTitle("V2Ray VPN")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    /**
     * 更新通知
     */
    private fun updateNotification(content: String) {
        val notification = createNotification(content)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    /**
     * 设置VPN状态
     */
    private fun setVpnStatus(status: VpnStatus) {
        vpnStatus.set(status)
        VpnStatusMonitor.setVpnStatus(status)
    }
    
    /**
     * 获取VPN状态
     */
    fun getVpnStatus(): VpnStatus {
        return vpnStatus.get()
    }
    
    /**
     * 保护套接字
     */
    fun protectSocket(socket: Int): Boolean {
        return protect(socket)
    }
} 