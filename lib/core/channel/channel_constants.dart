/// 定义所有与原生平台通信的通道常量
class ChannelConstants {
  /// 基础通道名称
  static const String baseChannel = 'com.v2ray.flutter';
  
  /// V2Ray服务通道
  static const String v2rayChannel = '$baseChannel/v2ray';
  
  /// V2Ray服务事件通道
  static const String v2rayEventChannel = '$v2rayChannel/events';
  
  /// V2Ray日志事件通道
  static const String v2rayLogChannel = '$v2rayChannel/logs';
  
  /// V2Ray流量统计事件通道
  static const String v2rayStatsChannel = '$v2rayChannel/stats';
  
  /// VPN服务通道
  static const String vpnChannel = '$baseChannel/vpn';
  
  /// VPN服务事件通道
  static const String vpnEventChannel = '$vpnChannel/events';
  
  /// 系统信息通道
  static const String systemChannel = '$baseChannel/system';
  
  /// 文件操作通道
  static const String fileChannel = '$baseChannel/file';
  
  // V2Ray方法名称
  /// 初始化V2Ray
  static const String methodV2rayInit = 'init';
  
  /// 启动V2Ray
  static const String methodV2rayStart = 'start';
  
  /// 停止V2Ray
  static const String methodV2rayStop = 'stop';
  
  /// 获取V2Ray版本
  static const String methodV2rayGetVersion = 'getVersion';
  
  /// 测试服务器延迟
  static const String methodV2rayTestLatency = 'testLatency';
  
  /// 获取上行流量
  static const String methodV2rayGetStatsUp = 'getStatsUp';
  
  /// 获取下行流量
  static const String methodV2rayGetStatsDown = 'getStatsDown';
  
  // VPN方法名称
  /// 初始化VPN
  static const String methodVpnInit = 'init';
  
  /// 启动VPN
  static const String methodVpnStart = 'start';
  
  /// 停止VPN
  static const String methodVpnStop = 'stop';
  
  /// 获取VPN状态
  static const String methodVpnGetStatus = 'getStatus';
  
  /// 检查VPN权限
  static const String methodVpnCheckPermission = 'checkPermission';
  
  /// 请求VPN权限
  static const String methodVpnRequestPermission = 'requestPermission';
  
  /// 设置VPN DNS
  static const String methodVpnSetDns = 'setDns';
  
  /// 设置VPN路由
  static const String methodVpnSetRoutes = 'setRoutes';
  
  // 系统方法名称
  /// 获取系统信息
  static const String methodSystemGetInfo = 'getInfo';
  
  /// 检查网络连接
  static const String methodSystemCheckNetwork = 'checkNetwork';
  
  // 文件方法名称
  /// 读取文件
  static const String methodFileRead = 'read';
  
  /// 写入文件
  static const String methodFileWrite = 'write';
  
  /// 删除文件
  static const String methodFileDelete = 'delete';
  
  /// 检查文件是否存在
  static const String methodFileExists = 'exists';
} 