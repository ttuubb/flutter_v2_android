import 'package:flutter/material.dart';
import 'package:flutter_v2_android/config/app_config.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';

/// 设置服务
class SettingsService extends ChangeNotifier {
  /// 存储服务
  final StorageService _storageService;
  
  /// 应用设置
  late AppSettings _settings;
  
  /// 当前应用设置
  AppSettings get currentSettings => _settings;
  
  /// 构造函数
  SettingsService(this._storageService);
  
  /// 初始化
  Future<void> init() async {
    await _loadSettings();
  }
  
  /// 加载设置
  Future<void> _loadSettings() async {
    final settingsJson = await _storageService.getObject(AppConfig.storageKeySettings);
    _settings = settingsJson != null 
        ? AppSettings.fromJson(settingsJson) 
        : AppSettings.defaultSettings();
    notifyListeners();
  }
  
  /// 保存设置
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    await _storageService.setObject(
      AppConfig.storageKeySettings,
      _settings.toJson(),
    );
    notifyListeners();
  }
  
  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    _settings = AppSettings.defaultSettings();
    await _storageService.setObject(
      AppConfig.storageKeySettings,
      _settings.toJson(),
    );
    notifyListeners();
  }
  
  /// 更新主题模式
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
    await _storageService.setObject(
      AppConfig.storageKeySettings,
      _settings.toJson(),
    );
    notifyListeners();
  }
  
  /// 更新语言
  Future<void> updateLanguage(String languageCode) async {
    _settings = _settings.copyWith(languageCode: languageCode);
    await _storageService.setObject(
      AppConfig.storageKeySettings,
      _settings.toJson(),
    );
    notifyListeners();
  }
} 