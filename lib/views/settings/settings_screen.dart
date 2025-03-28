import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/views/settings/about_screen.dart';

/// 设置界面
class SettingsScreen extends StatelessWidget {
  /// 构造函数
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '重置为默认设置',
            onPressed: () => _resetSettings(context),
          ),
        ],
      ),
      body: Consumer<AppSettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;
          
          return ListView(
            children: [
              // 常规设置
              _buildSectionHeader(context, '常规设置'),
              _buildSwitchTile(
                context: context,
                title: '自动启动',
                subtitle: '开机时自动启动应用',
                value: settings.autoStart,
                onChanged: (value) {
                  settingsProvider.updateSetting(autoStart: value);
                },
              ),
              _buildSwitchTile(
                context: context,
                title: '自动连接',
                subtitle: '启动时自动连接到上次使用的服务器',
                value: settings.autoConnect,
                onChanged: (value) {
                  settingsProvider.updateSetting(autoConnect: value);
                },
              ),
              _buildSwitchTile(
                context: context,
                title: '显示状态通知',
                subtitle: '在通知栏显示连接状态',
                value: settings.showNotification,
                onChanged: (value) {
                  settingsProvider.updateSetting(showNotification: value);
                },
              ),
              _buildSwitchTile(
                context: context,
                title: '显示流量速度',
                subtitle: '在通知中显示实时流量速度',
                value: settings.showTrafficSpeed,
                onChanged: (value) {
                  settingsProvider.updateSetting(showTrafficSpeed: value);
                },
              ),
              
              // 代理设置
              _buildSectionHeader(context, '代理设置'),
              _buildSwitchTile(
                context: context,
                title: '启用系统代理',
                subtitle: '启用VPN模式，接管所有流量',
                value: settings.enableSystemProxy,
                onChanged: (value) {
                  settingsProvider.updateSetting(enableSystemProxy: value);
                },
              ),
              _buildSwitchTile(
                context: context,
                title: '启用 UDP 支持',
                subtitle: '允许UDP流量通过代理',
                value: settings.enableUdp,
                onChanged: (value) {
                  settingsProvider.updateSetting(enableUdp: value);
                },
              ),
              _buildSwitchTile(
                context: context,
                title: '允许局域网访问',
                subtitle: '允许局域网设备通过本机代理上网',
                value: settings.shareLan,
                onChanged: (value) {
                  settingsProvider.updateSetting(shareLan: value);
                },
              ),
              
              // 端口设置
              _buildSectionHeader(context, '端口设置'),
              _buildNumberTile(
                context: context,
                title: 'HTTP 代理端口',
                value: settings.httpPort,
                minValue: 1024,
                maxValue: 65535,
                onChanged: (value) {
                  settingsProvider.updateSetting(httpPort: value);
                },
              ),
              _buildNumberTile(
                context: context,
                title: 'Socks5 代理端口',
                value: settings.socksPort,
                minValue: 1024,
                maxValue: 65535,
                onChanged: (value) {
                  settingsProvider.updateSetting(socksPort: value);
                },
              ),
              
              // 路由设置
              _buildSectionHeader(context, '路由设置'),
              _buildDropdownTile(
                context: context,
                title: '路由模式',
                value: settings.routingMode,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('全局')),
                  DropdownMenuItem(value: 1, child: Text('绕过局域网')),
                  DropdownMenuItem(value: 2, child: Text('绕过中国大陆')),
                  DropdownMenuItem(value: 3, child: Text('绕过局域网和中国大陆')),
                  DropdownMenuItem(value: 4, child: Text('自定义规则')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.updateSetting(routingMode: value);
                  }
                },
              ),
              _buildDropdownTile(
                context: context,
                title: '域名策略',
                value: settings.domainStrategy,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('AsIs')),
                  DropdownMenuItem(value: 1, child: Text('IPIfNonMatch')),
                  DropdownMenuItem(value: 2, child: Text('IPOnDemand')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.updateSetting(domainStrategy: value);
                  }
                },
              ),
              
              // DNS设置
              _buildSectionHeader(context, 'DNS设置'),
              _buildTextTile(
                context: context,
                title: '自定义DNS',
                value: settings.customDns,
                hint: '8.8.8.8,1.1.1.1',
                onChanged: (value) {
                  settingsProvider.updateSetting(customDns: value);
                },
              ),
              
              // 高级设置
              _buildSectionHeader(context, '高级设置'),
              _buildNumberTile(
                context: context,
                title: 'Mux 并发连接数',
                value: settings.muxConcurrency,
                minValue: 1,
                maxValue: 1024,
                onChanged: (value) {
                  settingsProvider.updateSetting(muxConcurrency: value);
                },
              ),
              
              // 外观设置
              _buildSectionHeader(context, '外观设置'),
              _buildDropdownTile(
                context: context,
                title: '主题模式',
                value: settings.themeMode.index,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('系统')),
                  DropdownMenuItem(value: 1, child: Text('亮色')),
                  DropdownMenuItem(value: 2, child: Text('暗色')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.updateSetting(
                      themeMode: ThemeMode.values[value],
                    );
                  }
                },
              ),
              
              // 订阅设置
              _buildSectionHeader(context, '订阅设置'),
              _buildSwitchTile(
                context: context,
                title: '自动更新',
                subtitle: '定期自动更新订阅',
                value: settings.autoUpdate,
                onChanged: (value) {
                  settingsProvider.updateSetting(autoUpdate: value);
                },
              ),
              _buildDropdownTile(
                context: context,
                title: '更新间隔',
                value: settings.subscriptionUpdateInterval,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('每天')),
                  DropdownMenuItem(value: 3, child: Text('每3天')),
                  DropdownMenuItem(value: 7, child: Text('每周')),
                  DropdownMenuItem(value: 30, child: Text('每月')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.updateSetting(
                      subscriptionUpdateInterval: value,
                    );
                  }
                },
                enabled: settings.autoUpdate,
              ),
              
              // 关于
              _buildSectionHeader(context, '关于'),
              ListTile(
                title: const Text('版本信息'),
                subtitle: const Text('V2ray Android 1.0.0'),
                leading: const Icon(Icons.info),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('开源协议'),
                subtitle: const Text('GPL-3.0'),
                leading: const Icon(Icons.description),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              
              // 底部留空
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
  
  /// 构建分区标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// 构建开关项
  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    bool enabled = true,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      dense: true,
      activeColor: Theme.of(context).primaryColor,
      enabled: enabled,
    );
  }
  
  /// 构建数字输入项
  Widget _buildNumberTile({
    required BuildContext context,
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    int minValue = 0,
    int maxValue = 99999,
    bool enabled = true,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text('当前值: $value'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: enabled && value > minValue
                ? () => onChanged(value - 1)
                : null,
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: enabled && value < maxValue
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
      enabled: enabled,
    );
  }
  
  /// 构建下拉选择项
  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        underline: Container(),
      ),
      enabled: enabled,
    );
  }
  
  /// 构建文本输入项
  Widget _buildTextTile({
    required BuildContext context,
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    bool enabled = true,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
        ),
        onChanged: enabled ? onChanged : null,
        enabled: enabled,
      ),
    );
  }
  
  /// 重置设置
  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppSettingsProvider>(context, listen: false)
                  .resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置为默认设置')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
} 