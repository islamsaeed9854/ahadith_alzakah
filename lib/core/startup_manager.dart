import 'dart:io';
import 'package:flutter/foundation.dart';

class StartupManager {
  
  static const String _appName = 'AhadithAlzakah';
  
  static const String _registryKey = r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run';

  
  static Future<bool> enableAutoStartup() async {
    if (!Platform.isWindows) return false;

    try {
     
      final executablePath = Platform.resolvedExecutable;
      
      final startupCommand = '"$executablePath" --startup';

      debugPrint('Enabling auto-startup with command: $startupCommand');

     
      final result = await Process.run('reg', [
        'add',
        _registryKey,
        '/v',
        _appName,
        '/t',
        'REG_SZ',
        '/d',
        startupCommand,
        '/f', 
      ], runInShell: true);

      if (result.exitCode == 0) {
        debugPrint('Auto-startup enabled successfully.');
        return true;
      } else {
        debugPrint('Failed to enable auto-startup. Stderr: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('Error enabling auto-startup: $e');
      return false;
    }
  }

 
  static Future<bool> disableAutoStartup() async {
    if (!Platform.isWindows) return false;
   
    return true;
  }

  
  static Future<bool> isAutoStartupEnabled() async {
    if (!Platform.isWindows) return false;
    
    return true;
  }
}