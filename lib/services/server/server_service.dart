import 'dart:convert';

import 'package:flutter_v2_android/config/app_config.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';
import 'package:uuid/uuid.dart';

/// 服务器管理服务
class ServerService {
  static final ServerService _instance = ServerService._internal();
  
  /// 单例模式
  factory ServerService() => _instance;
  
  /// 构造函数
  ServerService._internal();
  
  /// 存储服务
  final StorageService _storageService = StorageService();
  
  /// 服务器列表
  List<ServerConfig> _servers = [];
  
  /// 当前选中的服务器索引
  int _selectedServerIndex = -1;
  
  /// 获取服务器列表
  List<ServerConfig> get servers => List.unmodifiable(_servers);
  
  /// 获取当前选中的服务器
  ServerConfig? get selectedServer => 
      _selectedServerIndex >= 0 && _selectedServerIndex < _servers.length 
          ? _servers[_selectedServerIndex] 
          : null;
  
  /// 获取当前选中的服务器索引
  int get selectedServerIndex => _selectedServerIndex;
  
  /// 初始化
  Future<void> init() async {
    await _loadServers();
    await _loadSelectedServerIndex();
  }
  
  /// 加载服务器列表
  Future<void> _loadServers() async {
    final serverList = _storageService.getObjectList(AppConfig.storageKeyServers);
    if (serverList == null) {
      _servers = [];
    } else {
      _servers = serverList.map((json) => ServerConfig.fromJson(json)).toList();
    }
  }
  
  /// 加载选中的服务器索引
  Future<void> _loadSelectedServerIndex() async {
    _selectedServerIndex = _storageService.getInt(
      AppConfig.storageKeySelectedServer,
      defaultValue: _servers.isEmpty ? -1 : 0
    );
    
    // 确保索引有效
    if (_selectedServerIndex >= _servers.length) {
      _selectedServerIndex = _servers.isEmpty ? -1 : 0;
      await _saveSelectedServerIndex();
    }
  }
  
  /// 保存服务器列表
  Future<void> _saveServers() async {
    final List<Map<String, dynamic>> jsonList = _servers.map((server) => server.toJson()).toList();
    await _storageService.setObjectList(AppConfig.storageKeyServers, jsonList);
  }
  
  /// 保存选中的服务器索引
  Future<void> _saveSelectedServerIndex() async {
    await _storageService.setInt(AppConfig.storageKeySelectedServer, _selectedServerIndex);
  }
  
  /// 添加服务器
  Future<void> addServer(ServerConfig server) async {
    // 生成新ID的服务器
    final newServer = server.copyWith(
      id: const Uuid().v4(),
    );
    
    _servers.add(newServer);
    
    // 如果这是第一个服务器，自动选中
    if (_servers.length == 1) {
      _selectedServerIndex = 0;
      await _saveSelectedServerIndex();
    }
    
    await _saveServers();
  }
  
  /// 更新服务器
  Future<void> updateServer(ServerConfig server) async {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      _servers[index] = server;
      await _saveServers();
    }
  }
  
  /// 删除服务器
  Future<void> deleteServer(String serverId) async {
    final index = _servers.indexWhere((s) => s.id == serverId);
    if (index != -1) {
      _servers.removeAt(index);
      
      // 如果删除的是当前选中的服务器，重置选中
      if (index == _selectedServerIndex) {
        _selectedServerIndex = _servers.isEmpty ? -1 : 0;
        await _saveSelectedServerIndex();
      } else if (index < _selectedServerIndex) {
        // 如果删除的服务器在当前选中的服务器之前，调整索引
        _selectedServerIndex--;
        await _saveSelectedServerIndex();
      }
      
      await _saveServers();
    }
  }
  
  /// 选择服务器
  Future<void> selectServer(String serverId) async {
    final index = _servers.indexWhere((s) => s.id == serverId);
    if (index != -1) {
      _selectedServerIndex = index;
      await _saveSelectedServerIndex();
    }
  }
  
  /// 选择服务器（按索引）
  Future<void> selectServerByIndex(int index) async {
    if (index >= 0 && index < _servers.length) {
      _selectedServerIndex = index;
      await _saveSelectedServerIndex();
    }
  }
  
  /// 清空所有服务器
  Future<void> clearAllServers() async {
    _servers.clear();
    _selectedServerIndex = -1;
    await _saveServers();
    await _saveSelectedServerIndex();
  }
  
  /// 从分享链接添加服务器
  Future<ServerConfig?> addServerFromShareLink(String shareLink) async {
    final server = ServerConfig.fromShareLink(shareLink);
    if (server != null) {
      await addServer(server);
      return server;
    }
    return null;
  }
  
  /// 导出所有服务器为分享链接
  List<String> exportServersAsShareLinks() {
    return _servers.map((server) => server.generateShareLink()).toList();
  }
  
  /// 导入多个分享链接
  Future<List<ServerConfig>> importMultipleShareLinks(List<String> shareLinks) async {
    final importedServers = <ServerConfig>[];
    
    for (final link in shareLinks) {
      final server = await addServerFromShareLink(link);
      if (server != null) {
        importedServers.add(server);
      }
    }
    
    return importedServers;
  }
  
  /// 导出所有服务器为JSON字符串
  String exportServersAsJson() {
    final List<Map<String, dynamic>> jsonList = _servers.map((server) => server.toJson()).toList();
    return jsonEncode(jsonList);
  }
  
  /// 从JSON字符串导入服务器
  Future<List<ServerConfig>> importServersFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final importedServers = <ServerConfig>[];
      
      for (final json in jsonList) {
        if (json is Map<String, dynamic>) {
          final server = ServerConfig.fromJson(json);
          // 生成新ID避免冲突
          final newServer = server.copyWith(id: const Uuid().v4());
          importedServers.add(newServer);
          _servers.add(newServer);
        }
      }
      
      if (importedServers.isNotEmpty) {
        // 如果这是第一批服务器，自动选中第一个
        if (_servers.length == importedServers.length) {
          _selectedServerIndex = 0;
          await _saveSelectedServerIndex();
        }
        
        await _saveServers();
      }
      
      return importedServers;
    } catch (e) {
      print('导入服务器出错: $e');
      return [];
    }
  }
  
  /// 更新服务器延迟测试结果
  Future<void> updateServerLatency(String serverId, int latency) async {
    final index = _servers.indexWhere((s) => s.id == serverId);
    if (index != -1) {
      final updatedServer = _servers[index].copyWith(testResult: latency);
      _servers[index] = updatedServer;
      await _saveServers();
    }
  }
  
  /// 移动服务器位置
  Future<void> moveServer(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _servers.length || 
        newIndex < 0 || newIndex >= _servers.length) {
      return;
    }
    
    final server = _servers.removeAt(oldIndex);
    _servers.insert(newIndex, server);
    
    // 调整选中的服务器索引
    if (_selectedServerIndex == oldIndex) {
      _selectedServerIndex = newIndex;
      await _saveSelectedServerIndex();
    } else if (_selectedServerIndex > oldIndex && _selectedServerIndex <= newIndex) {
      _selectedServerIndex--;
      await _saveSelectedServerIndex();
    } else if (_selectedServerIndex < oldIndex && _selectedServerIndex >= newIndex) {
      _selectedServerIndex++;
      await _saveSelectedServerIndex();
    }
    
    await _saveServers();
  }
} 