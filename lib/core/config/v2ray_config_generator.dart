import 'dart:convert';

import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';

/// V2Ray配置生成器
class V2RayConfigGenerator {
  /// 生成v2ray配置
  static String generateConfig(ServerConfig serverConfig, AppSettings settings) {
    final Map<String, dynamic> configMap = {
      'inbounds': _generateInbounds(settings),
      'outbounds': _generateOutbounds(serverConfig),
      'routing': _generateRouting(settings),
      'dns': _generateDns(settings),
      'stats': {},
      'policy': _generatePolicy(),
    };
    
    return jsonEncode(configMap);
  }
  
  /// 生成入站配置
  static List<Map<String, dynamic>> _generateInbounds(AppSettings settings) {
    return [
      {
        'tag': 'socks',
        'port': settings.socksPort,
        'listen': settings.shareLan ? '0.0.0.0' : '127.0.0.1',
        'protocol': 'socks',
        'settings': {
          'auth': 'noauth',
          'udp': settings.enableUdp,
          'ip': settings.shareLan ? '0.0.0.0' : '127.0.0.1',
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls']
        }
      },
      {
        'tag': 'http',
        'port': settings.httpPort,
        'listen': settings.shareLan ? '0.0.0.0' : '127.0.0.1',
        'protocol': 'http',
        'settings': {
          'timeout': 300,
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls']
        }
      }
    ];
  }
  
  /// 生成出站配置
  static List<Map<String, dynamic>> _generateOutbounds(ServerConfig serverConfig) {
    return [
      _generateProxyOutbound(serverConfig),
      {
        'tag': 'direct',
        'protocol': 'freedom',
        'settings': {
          'domainStrategy': 'UseIP'
        }
      },
      {
        'tag': 'block',
        'protocol': 'blackhole',
        'settings': {
          'response': {
            'type': 'http'
          }
        }
      }
    ];
  }
  
  /// 生成代理出站配置
  static Map<String, dynamic> _generateProxyOutbound(ServerConfig serverConfig) {
    final Map<String, dynamic> streamSettings = {
      'network': serverConfig.network,
      'security': serverConfig.security,
    };
    
    // 根据不同传输协议添加特定设置
    switch (serverConfig.network) {
      case 'tcp':
        // TCP设置
        break;
      case 'kcp':
        // KCP设置
        break;
      case 'ws':
        // WebSocket设置
        break;
      case 'h2':
        // HTTP/2设置
        break;
      case 'quic':
        // QUIC设置
        break;
      case 'grpc':
        // gRPC设置
        break;
    }
    
    // 根据不同安全类型添加特定设置
    if (serverConfig.security == 'tls') {
      streamSettings['tlsSettings'] = {
        'allowInsecure': false,
        'serverName': '',
      };
    }
    
    // 根据不同协议生成不同的代理配置
    switch (serverConfig.protocol.toLowerCase()) {
      case 'vmess':
        return {
          'tag': 'proxy',
          'protocol': 'vmess',
          'settings': {
            'vnext': [
              {
                'address': serverConfig.address,
                'port': serverConfig.port,
                'users': [
                  {
                    'id': serverConfig.password,
                    'alterId': 0,
                    'security': serverConfig.encryption,
                    'level': 0
                  }
                ]
              }
            ]
          },
          'streamSettings': streamSettings,
          'mux': {
            'enabled': serverConfig.enableMux,
            'concurrency': serverConfig.muxConcurrency
          }
        };
        
      case 'vless':
        return {
          'tag': 'proxy',
          'protocol': 'vless',
          'settings': {
            'vnext': [
              {
                'address': serverConfig.address,
                'port': serverConfig.port,
                'users': [
                  {
                    'id': serverConfig.password,
                    'encryption': 'none',
                    'level': 0
                  }
                ]
              }
            ]
          },
          'streamSettings': streamSettings,
          'mux': {
            'enabled': serverConfig.enableMux,
            'concurrency': serverConfig.muxConcurrency
          }
        };
        
      case 'shadowsocks':
        return {
          'tag': 'proxy',
          'protocol': 'shadowsocks',
          'settings': {
            'servers': [
              {
                'address': serverConfig.address,
                'port': serverConfig.port,
                'method': serverConfig.encryption,
                'password': serverConfig.password,
                'level': 0
              }
            ]
          },
          'streamSettings': streamSettings,
          'mux': {
            'enabled': serverConfig.enableMux,
            'concurrency': serverConfig.muxConcurrency
          }
        };
        
      case 'trojan':
        return {
          'tag': 'proxy',
          'protocol': 'trojan',
          'settings': {
            'servers': [
              {
                'address': serverConfig.address,
                'port': serverConfig.port,
                'password': serverConfig.password,
                'level': 0
              }
            ]
          },
          'streamSettings': streamSettings,
          'mux': {
            'enabled': serverConfig.enableMux,
            'concurrency': serverConfig.muxConcurrency
          }
        };
        
      default:
        throw Exception('不支持的协议: ${serverConfig.protocol}');
    }
  }
  
  /// 生成路由配置
  static Map<String, dynamic> _generateRouting(AppSettings settings) {
    final List<Map<String, dynamic>> rules = [];
    
    // 根据路由模式设置不同的规则
    switch (settings.routingMode) {
      case 0: // 全局
        // 不添加规则，全部走代理
        break;
      
      case 1: // 绕过局域网
        rules.add({
          'type': 'field',
          'ip': ['geoip:private'],
          'outboundTag': 'direct'
        });
        break;
      
      case 2: // 绕过大陆
        rules.add({
          'type': 'field',
          'domain': ['geosite:cn'],
          'outboundTag': 'direct'
        });
        rules.add({
          'type': 'field',
          'ip': ['geoip:cn'],
          'outboundTag': 'direct'
        });
        break;
      
      case 3: // 绕过局域网和大陆
        rules.add({
          'type': 'field',
          'ip': ['geoip:private'],
          'outboundTag': 'direct'
        });
        rules.add({
          'type': 'field',
          'domain': ['geosite:cn'],
          'outboundTag': 'direct'
        });
        rules.add({
          'type': 'field',
          'ip': ['geoip:cn'],
          'outboundTag': 'direct'
        });
        break;
      
      case 4: // 全局直连
        rules.add({
          'type': 'field',
          'outboundTag': 'direct',
          'network': 'tcp,udp'
        });
        break;
      
      case 5: // 自定义
        // 这里应该加载自定义路由规则
        break;
    }
    
    return {
      'domainStrategy': 'IPIfNonMatch',
      'rules': rules
    };
  }
  
  /// 生成DNS配置
  static Map<String, dynamic> _generateDns(AppSettings settings) {
    return {
      'servers': [
        settings.customDns,
        '8.8.8.8',
        '1.1.1.1',
        {
          'address': '114.114.114.114',
          'port': 53,
          'domains': ['geosite:cn'],
          'expectIPs': ['geoip:cn']
        }
      ],
      'hosts': {
        'domain:v2ray.com': '127.0.0.1'
      }
    };
  }
  
  /// 生成策略配置
  static Map<String, dynamic> _generatePolicy() {
    return {
      'levels': {
        '0': {
          'handshake': 4,
          'connIdle': 300,
          'uplinkOnly': 2,
          'downlinkOnly': 5,
          'statsUserUplink': true,
          'statsUserDownlink': true,
          'bufferSize': 4096
        }
      },
      'system': {
        'statsInboundUplink': true,
        'statsInboundDownlink': true,
        'statsOutboundUplink': true,
        'statsOutboundDownlink': true
      }
    };
  }
} 