import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:uuid/uuid.dart';

/// 服务器编辑界面
class ServerEditScreen extends StatefulWidget {
  /// 待编辑的服务器配置，null表示添加新服务器
  final ServerConfig? serverConfig;
  
  /// 构造函数
  const ServerEditScreen({Key? key, this.serverConfig}) : super(key: key);
  
  @override
  State<ServerEditScreen> createState() => _ServerEditScreenState();
}

class _ServerEditScreenState extends State<ServerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  late final TextEditingController _remarksController;
  late final TextEditingController _addressController;
  late final TextEditingController _portController;
  late final TextEditingController _idController;
  late final TextEditingController _alterIdController;
  late final TextEditingController _securityController;
  late final TextEditingController _networkController;
  late final TextEditingController _headerTypeController;
  late final TextEditingController _requestHostController;
  late final TextEditingController _pathController;
  late final TextEditingController _streamSecurityController;
  late final TextEditingController _sniController;
  
  // 当前协议
  String _protocol = 'vmess';
  
  // UUID生成器
  final _uuid = const Uuid();
  
  @override
  void initState() {
    super.initState();
    
    // 初始化控制器
    final server = widget.serverConfig;
    
    _remarksController = TextEditingController(text: server?.remarks ?? '');
    _addressController = TextEditingController(text: server?.address ?? '');
    _portController = TextEditingController(text: server?.port.toString() ?? '443');
    _idController = TextEditingController(text: server?.id ?? _uuid.v4());
    _alterIdController = TextEditingController(text: server?.alterId.toString() ?? '0');
    _securityController = TextEditingController(text: server?.security ?? 'auto');
    _networkController = TextEditingController(text: server?.network ?? 'tcp');
    _headerTypeController = TextEditingController(text: server?.headerType ?? 'none');
    _requestHostController = TextEditingController(text: server?.requestHost ?? '');
    _pathController = TextEditingController(text: server?.path ?? '');
    _streamSecurityController = TextEditingController(text: server?.streamSecurity ?? '');
    _sniController = TextEditingController(text: server?.sni ?? '');
    
    // 设置当前协议
    if (server != null) {
      _protocol = server.protocol;
    }
  }
  
  @override
  void dispose() {
    // 释放控制器
    _remarksController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _idController.dispose();
    _alterIdController.dispose();
    _securityController.dispose();
    _networkController.dispose();
    _headerTypeController.dispose();
    _requestHostController.dispose();
    _pathController.dispose();
    _streamSecurityController.dispose();
    _sniController.dispose();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.serverConfig != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑服务器' : '添加服务器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存',
            onPressed: _saveServer,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 协议选择
            _buildProtocolSelector(),
            const SizedBox(height: 16),
            
            // 基本信息
            _buildSectionTitle('基本信息'),
            _buildTextField(
              controller: _remarksController,
              label: '备注',
              hint: '服务器备注名称',
              icon: Icons.label,
            ),
            _buildTextField(
              controller: _addressController,
              label: '地址',
              hint: '服务器地址',
              icon: Icons.language,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入服务器地址';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _portController,
              label: '端口',
              hint: '服务器端口',
              icon: Icons.dialpad,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入端口';
                }
                final port = int.tryParse(value);
                if (port == null || port <= 0 || port > 65535) {
                  return '端口范围: 1-65535';
                }
                return null;
              },
            ),
            
            // VMess/VLESS特有配置
            if (_protocol == 'vmess' || _protocol == 'vless') ...[
              const SizedBox(height: 16),
              _buildSectionTitle('${_protocol.toUpperCase()} 配置'),
              _buildTextField(
                controller: _idController,
                label: 'ID',
                hint: 'UUID',
                icon: Icons.perm_identity,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入ID';
                  }
                  return null;
                },
              ),
              
              if (_protocol == 'vmess') ...[
                _buildTextField(
                  controller: _alterIdController,
                  label: 'alterId',
                  hint: '0',
                  icon: Icons.confirmation_number,
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownField(
                  controller: _securityController,
                  label: '加密方式',
                  icon: Icons.enhanced_encryption,
                  items: const ['auto', 'aes-128-gcm', 'chacha20-poly1305', 'none'],
                ),
              ],
            ],
            
            // 传输配置
            const SizedBox(height: 16),
            _buildSectionTitle('传输配置'),
            _buildDropdownField(
              controller: _networkController,
              label: '传输协议',
              icon: Icons.settings_ethernet,
              items: const ['tcp', 'kcp', 'ws', 'http', 'quic', 'grpc'],
              onChanged: (value) {
                setState(() {});
              },
            ),
            
            // HTTP/WebSocket/gRPC 设置
            if (_networkController.text == 'http' || _networkController.text == 'ws' || _networkController.text == 'grpc') ...[
              _buildTextField(
                controller: _requestHostController,
                label: '主机名',
                hint: '伪装域名',
                icon: Icons.domain,
              ),
            ],
            
            // WebSocket/HTTP/gRPC 路径
            if (_networkController.text == 'ws' || _networkController.text == 'http' || _networkController.text == 'grpc') ...[
              _buildTextField(
                controller: _pathController,
                label: '路径',
                hint: '/',
                icon: Icons.subdirectory_arrow_right,
              ),
            ],
            
            // KCP/QUIC 设置
            if (_networkController.text == 'kcp' || _networkController.text == 'quic') ...[
              _buildDropdownField(
                controller: _headerTypeController,
                label: '伪装类型',
                icon: Icons.style,
                items: const ['none', 'srtp', 'utp', 'wechat-video', 'dtls', 'wireguard'],
              ),
            ],
            
            // TLS设置
            const SizedBox(height: 16),
            _buildSectionTitle('TLS 设置'),
            _buildSwitchField(
              controller: _streamSecurityController,
              label: '启用 TLS',
              icon: Icons.security,
              value: _streamSecurityController.text == 'tls',
              onChanged: (value) {
                _streamSecurityController.text = value ? 'tls' : '';
                setState(() {});
              },
            ),
            
            // SNI设置
            if (_streamSecurityController.text == 'tls') ...[
              _buildTextField(
                controller: _sniController,
                label: 'SNI',
                hint: '服务器名称指示',
                icon: Icons.domain_verification,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建协议选择器
  Widget _buildProtocolSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                '代理协议',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                _buildProtocolChip('vmess', '💙 VMess'),
                _buildProtocolChip('vless', '💜 VLESS'),
                _buildProtocolChip('shadowsocks', '💚 Shadowsocks'),
                _buildProtocolChip('trojan', '💛 Trojan'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建协议选择芯片
  Widget _buildProtocolChip(String protocol, String label) {
    final isSelected = _protocol == protocol;
    
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _protocol = protocol;
          });
        }
      },
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
  
  /// 构建下拉选择框
  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: items.contains(controller.text) ? controller.text : items.first,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
            if (onChanged != null) {
              onChanged(value);
            }
          }
        },
      ),
    );
  }
  
  /// 构建开关选择框
  Widget _buildSwitchField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  /// 保存服务器配置
  void _saveServer() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    try {
      // 创建服务器配置
      final serverConfig = ServerConfig(
        id: widget.serverConfig?.id ?? _uuid.v4(),
        remarks: _remarksController.text,
        address: _addressController.text,
        port: int.parse(_portController.text),
        protocol: _protocol,
        // VMess/VLESS 配置
        alterId: int.tryParse(_alterIdController.text) ?? 0,
        security: _securityController.text,
        // 传输层配置
        network: _networkController.text,
        headerType: _headerTypeController.text,
        requestHost: _requestHostController.text,
        path: _pathController.text,
        streamSecurity: _streamSecurityController.text,
        sni: _sniController.text,
        // v2ray-core使用的ID字段
        uuid: _idController.text,
      );
      
      // 保存服务器配置
      final serverProvider = Provider.of<ServerProvider>(context, listen: false);
      
      if (widget.serverConfig != null) {
        // 更新服务器
        serverProvider.updateServer(serverConfig);
      } else {
        // 添加服务器
        serverProvider.addServer(serverConfig);
      }
      
      // 返回上一页
      Navigator.of(context).pop();
    } catch (e) {
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
 