import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 本地存储服务
class StorageService {
  static final StorageService _instance = StorageService._internal();
  
  /// 单例模式
  factory StorageService() => _instance;
  
  /// 内部构造函数
  StorageService._internal();
  
  /// SharedPreferences实例
  late SharedPreferences _prefs;
  
  /// 安全存储实例
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// 初始化存储服务
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  /// 获取字符串
  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }
  
  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  /// 获取整数
  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }
  
  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  /// 获取布尔值
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }
  
  /// 保存字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  /// 获取字符串列表
  List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    return _prefs.getStringList(key) ?? defaultValue;
  }
  
  /// 保存对象（JSON序列化）
  Future<bool> setObject(String key, Object value) async {
    return await _prefs.setString(key, jsonEncode(value));
  }
  
  /// 获取对象（JSON反序列化）
  Map<String, dynamic>? getObject(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('解析JSON失败: $e');
      return null;
    }
  }
  
  /// 获取对象列表（JSON反序列化）
  List<Map<String, dynamic>>? getObjectList(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('解析JSON列表失败: $e');
      return null;
    }
  }
  
  /// 保存对象列表（JSON序列化）
  Future<bool> setObjectList(String key, List<dynamic> value) async {
    return await _prefs.setString(key, jsonEncode(value));
  }
  
  /// 删除指定键的值
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  /// 清除所有数据
  Future<bool> clear() async {
    return await _prefs.clear();
  }
  
  /// 检查键是否存在
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  /// 安全存储 - 保存
  Future<void> secureSet(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  /// 安全存储 - 获取
  Future<String?> secureGet(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  /// 安全存储 - 删除
  Future<void> secureDelete(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// 安全存储 - 清除所有
  Future<void> secureClear() async {
    await _secureStorage.deleteAll();
  }
} 