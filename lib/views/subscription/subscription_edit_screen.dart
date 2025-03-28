import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/models/config/subscription.dart';
import 'package:uuid/uuid.dart';

/// 订阅编辑界面
class SubscriptionEditScreen extends StatefulWidget {
  /// 待编辑的订阅，如果为null则表示添加新订阅
  final Subscription? subscription;
  
  /// 构造函数
  const SubscriptionEditScreen({Key? key, this.subscription}) : super(key: key);
  
  @override
  State<SubscriptionEditScreen> createState() => _SubscriptionEditScreenState();
}

class _SubscriptionEditScreenState extends State<SubscriptionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  
  // 自动更新
  late bool _autoUpdate;
  
  // 更新间隔
  late int _updateInterval;
  
  // 是否是编辑模式
  bool get _isEditing => widget.subscription != null;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化表单控制器
    final subscription = widget.subscription;
    
    _nameController = TextEditingController(text: subscription?.name ?? '');
    _urlController = TextEditingController(text: subscription?.url ?? '');
    _autoUpdate = subscription?.autoUpdate ?? true;
    _updateInterval = subscription?.updateInterval ?? 1;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑订阅' : '添加订阅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存',
            onPressed: _saveSubscription,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            _buildSectionTitle('基本信息'),
            _buildTextField(
              controller: _nameController,
              label: '名称',
              hint: '订阅名称',
              icon: Icons.label,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入订阅名称';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _urlController,
              label: 'URL',
              hint: 'https://example.com/sub',
              icon: Icons.link,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入订阅URL';
                }
                if (!Uri.tryParse(value)!.isAbsolute) {
                  return '请输入有效的URL';
                }
                return null;
              },
              keyboardType: TextInputType.url,
            ),
            
            // 自动更新设置
            _buildSectionTitle('更新设置'),
            _buildSwitchField(
              title: '自动更新',
              subtitle: '定期自动更新订阅内容',
              value: _autoUpdate,
              onChanged: (value) {
                setState(() {
                  _autoUpdate = value;
                });
              },
            ),
            _buildDropdownField(
              title: '更新间隔',
              value: _updateInterval,
              items: const [
                DropdownMenuItem(value: 1, child: Text('每天')),
                DropdownMenuItem(value: 3, child: Text('每3天')),
                DropdownMenuItem(value: 7, child: Text('每周')),
                DropdownMenuItem(value: 14, child: Text('每两周')),
                DropdownMenuItem(value: 30, child: Text('每月')),
              ],
              onChanged: _autoUpdate
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _updateInterval = value;
                        });
                      }
                    }
                  : null,
            ),
            
            // 粘贴按钮
            if (!_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.paste),
                label: const Text('从剪贴板粘贴'),
                onPressed: _pasteFromClipboard,
              ),
            ],
            
            // 如果是编辑模式，显示更新按钮
            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('立即更新'),
                onPressed: _updateSubscription,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// 构建文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
  
  /// 构建开关设置
  Widget _buildSwitchField({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SwitchListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
  
  /// 构建下拉选择框
  Widget _buildDropdownField<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: Container(),
          ),
        ],
      ),
    );
  }
  
  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('剪贴板为空')),
      );
      return;
    }
    
    // 尝试解析为URL
    if (Uri.tryParse(text)?.isAbsolute == true) {
      _urlController.text = text;
      
      // 尝试自动设置名称（如果当前为空）
      if (_nameController.text.isEmpty) {
        final uri = Uri.parse(text);
        _nameController.text = uri.host;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的URL')),
      );
    }
  }
  
  /// 保存订阅
  Future<void> _saveSubscription() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      
      if (_isEditing) {
        // 更新现有订阅
        final updatedSubscription = widget.subscription!.copyWith(
          name: _nameController.text,
          url: _urlController.text,
          autoUpdate: _autoUpdate,
          updateInterval: _updateInterval,
        );
        
        await subscriptionProvider.updateSubscriptionInfo(updatedSubscription);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订阅已更新')),
        );
      } else {
        // 添加新订阅
        await subscriptionProvider.addSubscription(
          _nameController.text,
          _urlController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订阅已添加并开始更新')),
        );
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }
  
  /// 更新订阅
  Future<void> _updateSubscription() async {
    if (!_isEditing) return;
    
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final success = await subscriptionProvider.updateSubscription(widget.subscription!.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订阅更新成功')),
        );
      } else {
        final errorMessage = subscriptionProvider.getLastUpdateStatus(widget.subscription!.id) ?? '更新失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    }
  }
} 