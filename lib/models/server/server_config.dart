import 'dart:convert';

/// 服务器配置模型
class ServerConfig {
  /// 服务器唯一标识
  final String id;
  
  /// 服务器备注名
  final String name;
  
  /// 服务器地址
  final String address;
  
  /// 服务器端口
  final int port;
  
  /// 协议类型（vmess, vless, shadowsocks, trojan等）
  final String protocol;
  
  /// 用户ID/密码
  final String password;
  
  /// 别名（显示名称）
  final String alias;
  
  /// 加密方式
  final String encryption;
  
  /// 传输方式（tcp, kcp, ws, h2, quic等）
  final String network;
  
  /// 传输层安全 (tls, none)
  final String security;
  
  /// 是否启用多路复用
  final bool enableMux;
  
  /// 多路复用并发连接数
  final int muxConcurrency;
  
  /// 备注信息
  final String remarks;
  
  /// 是否来自订阅
  final bool fromSubscription;
  
  /// 订阅地址（如果来自订阅）
  final String? subscriptionUrl;
  
  /// 测试结果（延迟，毫秒）
  int? testResult;
  
  /// 构造函数
  ServerConfig({
    required this.id,
    required this.name, 
    required this.address,
    required this.port,
    required this.protocol,
    required this.password,
    this.alias = '',
    this.encryption = 'auto',
    this.network = 'tcp',
    this.security = 'none',
    this.enableMux = true,
    this.muxConcurrency = 8,
    this.remarks = '',
    this.fromSubscription = false,
    this.subscriptionUrl,
    this.testResult,
  });
  
  /// 从JSON构建对象
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      port: json['port'] ?? 0,
      protocol: json['protocol'] ?? '',
      password: json['password'] ?? '',
      alias: json['alias'] ?? '',
      encryption: json['encryption'] ?? 'auto',
      network: json['network'] ?? 'tcp',
      security: json['security'] ?? 'none',
      enableMux: json['enableMux'] ?? true,
      muxConcurrency: json['muxConcurrency'] ?? 8,
      remarks: json['remarks'] ?? '',
      fromSubscription: json['fromSubscription'] ?? false,
      subscriptionUrl: json['subscriptionUrl'],
      testResult: json['testResult'],
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'port': port,
      'protocol': protocol,
      'password': password,
      'alias': alias,
      'encryption': encryption,
      'network': network,
      'security': security,
      'enableMux': enableMux,
      'muxConcurrency': muxConcurrency,
      'remarks': remarks,
      'fromSubscription': fromSubscription,
      'subscriptionUrl': subscriptionUrl,
      'testResult': testResult,
    };
  }
  
  /// 从分享链接解析服务器配置
  static ServerConfig? fromShareLink(String link) {
    // 根据不同协议解析分享链接的逻辑
    // 这里只是示例，实际实现需要支持各种协议的解析
    try {
      if (link.startsWith('vmess://')) {
        return _parseVmessLink(link);
      } else if (link.startsWith('vless://')) {
        return _parseVlessLink(link);
      } else if (link.startsWith('ss://')) {
        return _parseShadowsocksLink(link);
      } else if (link.startsWith('trojan://')) {
        return _parseTrojanLink(link);
      }
    } catch (e) {
      print('解析分享链接失败: $e');
    }
    return null;
  }
  
  /// 解析VMess分享链接
  static ServerConfig? _parseVmessLink(String link) {
    try {
      final vmessContent = link.substring(8); // 移除 'vmess://'
      final decoded = utf8.decode(base64.decode(vmessContent));
      final json = jsonDecode(decoded);
      
      return ServerConfig(
        id: json['id'] ?? '',
        name: json['ps'] ?? '',
        address: json['add'] ?? '',
        port: int.tryParse(json['port'].toString()) ?? 0,
        protocol: 'vmess',
        password: json['id'] ?? '',
        network: json['net'] ?? 'tcp',
        security: json['tls'] ?? 'none',
      );
    } catch (e) {
      print('解析VMess链接失败: $e');
      return null;
    }
  }
  
  /// 解析VLESS分享链接
  static ServerConfig? _parseVlessLink(String link) {
    // VLESS链接解析逻辑（占位）
    return null;
  }
  
  /// 解析Shadowsocks分享链接
  static ServerConfig? _parseShadowsocksLink(String link) {
    // Shadowsocks链接解析逻辑（占位）
    return null;
  }
  
  /// 解析Trojan分享链接
  static ServerConfig? _parseTrojanLink(String link) {
    // Trojan链接解析逻辑（占位）
    return null;
  }
  
  /// 生成分享链接
  String generateShareLink() {
    // 根据不同协议生成分享链接的逻辑
    // 这里只是示例，实际实现需要支持各种协议的生成
    switch (protocol.toLowerCase()) {
      case 'vmess':
        return _generateVmessLink();
      case 'vless':
        return _generateVlessLink();
      case 'shadowsocks':
        return _generateShadowsocksLink();
      case 'trojan':
        return _generateTrojanLink();
      default:
        return '';
    }
  }
  
  /// 生成VMess分享链接
  String _generateVmessLink() {
    final Map<String, dynamic> configMap = {
      'v': '2',
      'ps': name,
      'add': address,
      'port': port.toString(),
      'id': password,
      'aid': '0',
      'net': network,
      'type': 'none',
      'host': '',
      'path': '',
      'tls': security,
    };
    
    final jsonStr = jsonEncode(configMap);
    final base64Str = base64.encode(utf8.encode(jsonStr));
    return 'vmess://$base64Str';
  }
  
  /// 生成VLESS分享链接
  String _generateVlessLink() {
    // VLESS链接生成逻辑（占位）
    return '';
  }
  
  /// 生成Shadowsocks分享链接
  String _generateShadowsocksLink() {
    // Shadowsocks链接生成逻辑（占位）
    return '';
  }
  
  /// 生成Trojan分享链接
  String _generateTrojanLink() {
    // Trojan链接生成逻辑（占位）
    return '';
  }
  
  /// 创建副本
  ServerConfig copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    String? protocol,
    String? password,
    String? alias,
    String? encryption,
    String? network,
    String? security,
    bool? enableMux,
    int? muxConcurrency,
    String? remarks,
    bool? fromSubscription,
    String? subscriptionUrl,
    int? testResult,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      password: password ?? this.password,
      alias: alias ?? this.alias,
      encryption: encryption ?? this.encryption,
      network: network ?? this.network,
      security: security ?? this.security,
      enableMux: enableMux ?? this.enableMux,
      muxConcurrency: muxConcurrency ?? this.muxConcurrency,
      remarks: remarks ?? this.remarks,
      fromSubscription: fromSubscription ?? this.fromSubscription,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      testResult: testResult ?? this.testResult,
    );
  }
} 