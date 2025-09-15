import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StartupManager {
  static const String _appName = 'AhadithAlzakah';
  static const String _registryKey = r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run';
  
  /// Enable auto-startup by adding registry entry
  static Future<bool> enableAutoStartup() async {
    if (!Platform.isWindows) {
      debugPrint('Auto-startup is only supported on Windows');
      return false;
    }

    try {
      final executablePath = Platform.resolvedExecutable;
      final startupCommand = '"$executablePath" --startup';
      
      debugPrint('Adding auto-startup registry entry');
      debugPrint('Executable path: $executablePath');
      debugPrint('Startup command: $startupCommand');

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
      ]);

      if (result.exitCode == 0) {
        debugPrint('✓ Auto-startup enabled successfully');
        return true;
      } else {
        debugPrint('✗ Failed to enable auto-startup: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('✗ Error enabling auto-startup: $e');
      return false;
    }
  }

  /// Disable auto-startup by removing registry entry
  static Future<bool> disableAutoStartup() async {
    if (!Platform.isWindows) {
      debugPrint('Auto-startup is only supported on Windows');
      return false;
    }

    try {
      debugPrint('Removing auto-startup registry entry');

      // Remove registry entry using reg delete command
      final result = await Process.run('reg', [
        'delete',
        _registryKey,
        '/v',
        _appName,
        '/f', // Force delete without confirmation
      ]);

      if (result.exitCode == 0) {
        debugPrint('✓ Auto-startup disabled successfully');
        return true;
      } else {
        // Exit code 1 usually means the key doesn't exist, which is fine
        if (result.exitCode == 1) {
          debugPrint('✓ Auto-startup was already disabled');
          return true;
        }
        debugPrint('✗ Failed to disable auto-startup: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('✗ Error disabling auto-startup: $e');
      return false;
    }
  }

  /// Check if auto-startup is currently enabled
  static Future<bool> isAutoStartupEnabled() async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      // Query registry entry using reg query command
      final result = await Process.run('reg', [
        'query',
        _registryKey,
        '/v',
        _appName,
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        debugPrint('Registry query result: $output');
        
        // Check if our app is in the output
        final isEnabled = output.contains(_appName) && output.contains('--startup');
        debugPrint('Auto-startup status: ${isEnabled ? "enabled" : "disabled"}');
        return isEnabled;
      } else {
        debugPrint('Auto-startup registry entry not found');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking auto-startup status: $e');
      return false;
    }
  }

  /// Get the current startup command from registry
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
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        
        for (final line in lines) {
          if (line.trim().startsWith(_appName)) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              return parts.skip(2).join(' '); // Skip name and type, get the value
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting startup command: $e');
      return null;
    }
  }

  /// Validate that the current executable path matches the registry entry
  static Future<bool> validateStartupEntry() async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      final currentPath = Platform.resolvedExecutable;
      final registryCommand = await getStartupCommand();
      
      if (registryCommand == null) {
        return false;
      }

      // Remove quotes and --startup flag for comparison
      final registryPath = registryCommand
          .replaceAll('"', '')
          .replaceAll(' --startup', '')
          .trim();

      final isValid = path.equals(currentPath, registryPath);
      
      if (!isValid) {
        debugPrint('Startup entry path mismatch:');
        debugPrint('Current: $currentPath');
        debugPrint('Registry: $registryPath');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('Error validating startup entry: $e');
      return false;
    }
  }

  /// Update startup entry if path has changed
  static Future<bool> updateStartupEntry() async {
    if (!Platform.isWindows) {
      return false;
    }

    final isEnabled = await isAutoStartupEnabled();
    if (!isEnabled) {
      return true; // Nothing to update
    }

    final isValid = await validateStartupEntry();
    if (isValid) {
      return true; // Already up to date
    }

    debugPrint('Updating startup entry with new path');
    return await enableAutoStartup(); // This will overwrite the existing entry
  }
}