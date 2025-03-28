import 'dart:async';

import 'package:flutter_v2_android/models/config/app_settings.dart';

/// VPN状态
enum VpnStatus {
  /// 已断开连接
  disconnected,
  /// 正在连接
  connecting,
  /// 已连接
  connected,
  /// 正在断开连接
  disconnecting,
  /// 发生错误
  error,
}

/// 流量统计数据
class TrafficStats {
  /// 上传速度（字节/秒）
  final int uploadSpeed;
  
  /// 下载速度（字节/秒）
  final int downloadSpeed;
  
  /// 总上传流量（字节）
  final int totalUpload;
  
  /// 总下载流量（字节）
  final int totalDownload;
  
  /// 构造函数
  TrafficStats({
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.totalUpload = 0,
    this.totalDownload = 0,
  });
}

/// VPN服务接口
abstract class VpnService {
  /// 获取当前状态
  VpnStatus get status;
  
  /// 获取状态流
  Stream<VpnStatus> get statusStream;
  
  /// 初始化VPN服务
  Future<void> init();
  
  /// 启动VPN服务
  /// 
  /// [settings] 应用程序设置
  /// 返回是否成功启动
  Future<bool> start(AppSettings settings);
  
  /// 停止VPN服务
  /// 
  /// 返回是否成功停止
  Future<bool> stop();
  
  /// 检查是否拥有VPN权限
  /// 
  /// 返回是否拥有权限
  Future<bool> checkPermission();
  
  /// 请求VPN权限
  /// 
  /// 返回是否获取权限
  Future<bool> requestPermission();
  
  /// 设置VPN DNS
  /// 
  /// [dns] DNS服务器地址列表
  /// 返回是否设置成功
  Future<bool> setDns(List<String> dns);
  
  /// 设置VPN路由
  /// 
  /// [routes] 路由规则列表
  /// 返回是否设置成功
  Future<bool> setRoutes(List<String> routes);
  
  /// 清理资源
  Future<void> dispose();
} 