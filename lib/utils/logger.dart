import 'dart:developer' as developer;

/// 日志工具类
class LoggerUtil {
  /// 是否启用调试日志
  static bool debugEnabled = true;
  
  /// 日志级别
  enum LogLevel {
    /// 调试
    debug,
    /// 信息
    info,
    /// 警告
    warn,
    /// 错误
    error,
  }
  
  /// 记录调试日志
  static void debug(String message) {
    if (debugEnabled) {
      _log(LogLevel.debug, message);
    }
  }
  
  /// 记录信息日志
  static void info(String message) {
    _log(LogLevel.info, message);
  }
  
  /// 记录警告日志
  static void warn(String message) {
    _log(LogLevel.warn, message);
  }
  
  /// 记录错误日志
  static void error(String message) {
    _log(LogLevel.error, message);
  }
  
  /// 记录异常日志
  static void exception(dynamic exception, [StackTrace? stackTrace]) {
    final message = stackTrace != null 
        ? '$exception\n$stackTrace' 
        : exception.toString();
    _log(LogLevel.error, message);
  }
  
  /// 记录日志的内部方法
  static void _log(LogLevel level, String message) {
    final formattedMessage = _formatMessage(level, message);
    
    // 使用dart:developer记录日志
    developer.log(
      message,
      name: 'V2Ray',
      level: _levelToInt(level),
      time: DateTime.now(),
    );
    
    // 同时打印到控制台
    print(formattedMessage);
  }
  
  /// 格式化日志消息
  static String _formatMessage(LogLevel level, String message) {
    final timestamp = _getTimestamp();
    final levelString = _levelToString(level);
    return '[$timestamp] $levelString: $message';
  }
  
  /// 获取当前时间戳
  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}';
  }
  
  /// 将数字填充为固定长度
  static String _pad(int n, [int width = 2]) {
    return n.toString().padLeft(width, '0');
  }
  
  /// 日志级别转字符串
  static String _levelToString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
  
  /// 日志级别转整数
  static int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
} 