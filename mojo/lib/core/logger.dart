import 'package:flutter/foundation.dart';

class Logger {
  final String _tag;

  Logger(this._tag);

  void d(String message) {
    if (kDebugMode) {
      print('🐛 $_tag: $message');
    }
  }

  void i(String message) {
    if (kDebugMode) {
      print('💡 $_tag: $message');
    }
  }

  void w(String message) {
    if (kDebugMode) {
      print('⚠️ $_tag: $message');
    }
  }

  void e(String message) {
    if (kDebugMode) {
      print('❌ $_tag: $message');
    }
  }
} 