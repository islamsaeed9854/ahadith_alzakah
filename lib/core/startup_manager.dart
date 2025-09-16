import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StartupManager {
  static const String _appName = 'AhadithAlzakah';
  static const String _registryKey = r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run';
  
  /// Enable auto-startup by adding registry entry with enhanced debugging
  static Future<bool> enableAutoStartup() async {
    if (!Platform.isWindows) {
      debugPrint('❌ Auto-startup is only supported on Windows');
      return false;
    }

    try {
      final executablePath = Platform.resolvedExecutable;
      final startupCommand = '"$executablePath" --startup';
      
      debugPrint('🔧 Enabling auto-startup...');
      debugPrint('📁 Executable path: $executablePath');
      debugPrint('📝 Startup command: $startupCommand');
      debugPrint('🔑 Registry key: $_registryKey');

      // Check if executable path exists
      if (!File(executablePath).existsSync()) {
        debugPrint('❌ Executable file does not exist at path: $executablePath');
        return false;
      }

      // Test if reg command is available
      try {
        final testResult = await Process.run('reg', ['/?'], runInShell: true);
        debugPrint('✅ reg command available, exit code: ${testResult.exitCode}');
      } catch (e) {
        debugPrint('❌ reg command not available: $e');
        return false;
      }

      // Add registry entry using reg add command
      final result = await Process.run('reg', [
        'add',
        _registryKey,
        '/v',
        _appName,
        '/t',
        'REG_SZ',
        '/d',
        startupCommand,
        '/f', // Force overwrite if exists
      ], runInShell: true);

      debugPrint('📊 Registry add result:');
      debugPrint('   Exit code: ${result.exitCode}');
      debugPrint('   Stdout: ${result.stdout}');
      debugPrint('   Stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        // Verify the entry was actually added
        final verification = await isAutoStartupEnabled();
        if (verification) {
          debugPrint('✅ Auto-startup enabled and verified successfully');
          return true;
        } else {
          debugPrint('❌ Auto-startup command succeeded but verification failed');
          return false;
        }
      } else {
        debugPrint('❌ Failed to enable auto-startup: ${result.stderr}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error enabling auto-startup: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Disable auto-startup with enhanced debugging
  static Future<bool> disableAutoStartup() async {
    if (!Platform.isWindows) {
      debugPrint('❌ Auto-startup is only supported on Windows');
      return false;
    }

    try {
      debugPrint('🔧 Disabling auto-startup...');
      debugPrint('🔑 Registry key: $_registryKey');
      debugPrint('📝 Value name: $_appName');

      // Remove registry entry using reg delete command
      final result = await Process.run('reg', [
        'delete',
        _registryKey,
        '/v',
        _appName,
        '/f', // Force delete without confirmation
      ], runInShell: true);

      debugPrint('📊 Registry delete result:');
      debugPrint('   Exit code: ${result.exitCode}');
      debugPrint('   Stdout: ${result.stdout}');
      debugPrint('   Stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        debugPrint('✅ Auto-startup disabled successfully');
        return true;
      } else {
        // Exit code 1 usually means the key doesn't exist, which is fine
        if (result.exitCode == 1) {
          debugPrint('✅ Auto-startup was already disabled (key not found)');
          return true;
        }
        debugPrint('❌ Failed to disable auto-startup: ${result.stderr}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error disabling auto-startup: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if auto-startup is currently enabled with enhanced debugging
  static Future<bool> isAutoStartupEnabled() async {
    if (!Platform.isWindows) {
      debugPrint('❌ Not Windows platform');
      return false;
    }

    try {
      debugPrint('🔍 Checking auto-startup status...');
      debugPrint('🔑 Querying registry key: $_registryKey');
      debugPrint('📝 Value name: $_appName');

      // Query registry entry using reg query command
      final result = await Process.run('reg', [
        'query',
        _registryKey,
        '/v',
        _appName,
      ], runInShell: true);

      debugPrint('📊 Registry query result:');
      debugPrint('   Exit code: ${result.exitCode}');
      debugPrint('   Stdout: ${result.stdout}');
      debugPrint('   Stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        
        // Check if our app is in the output
        final containsAppName = output.contains(_appName);
        final containsStartupFlag = output.contains('--startup');
        final isEnabled = containsAppName && containsStartupFlag;
        
        debugPrint('🔍 Analysis:');
        debugPrint('   Contains app name: $containsAppName');
        debugPrint('   Contains --startup flag: $containsStartupFlag');
        debugPrint('   Final status: ${isEnabled ? "ENABLED" : "DISABLED"}');
        
        return isEnabled;
      } else {
        debugPrint('❌ Auto-startup registry entry not found (exit code: ${result.exitCode})');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking auto-startup status: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get the current startup command from registry with debugging
  static Future<String?> getStartupCommand() async {
    if (!Platform.isWindows) {
      return null;
    }

    try {
      final result = await Process.run('reg', [
        'query',
        _registryKey,
        '/v',
        _appName,
      ], runInShell: true);

      debugPrint('📊 Getting startup command:');
      debugPrint('   Exit code: ${result.exitCode}');

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        debugPrint('   Raw output: $output');
        
        final lines = output.split('\n');
        
        for (final line in lines) {
          debugPrint('   Processing line: "${line.trim()}"');
          if (line.trim().startsWith(_appName)) {
            final parts = line.trim().split(RegExp(r'\s+'));
            debugPrint('   Split parts: $parts');
            if (parts.length >= 3) {
              final command = parts.skip(2).join(' ');
              debugPrint('   Extracted command: $command');
              return command;
            }
          }
        }
        debugPrint('   No matching line found');
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting startup command: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Test registry access permissions
  static Future<bool> testRegistryAccess() async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      debugPrint('🔧 Testing registry access...');
      
      // Try to read the entire Run key
      final result = await Process.run('reg', [
        'query',
        _registryKey,
      ], runInShell: true);

      debugPrint('📊 Registry access test:');
      debugPrint('   Exit code: ${result.exitCode}');
      debugPrint('   Can read registry: ${result.exitCode == 0}');
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        debugPrint('   Registry entries found: ${output.split('\n').length}');
        return true;
      } else {
        debugPrint('   Error: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Registry access test failed: $e');
      return false;
    }
  }
}