// lib/core/single_instance.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Ensures only one instance of the application is running using a lock file and a local server.
class SingleInstance {
  static const _lockFileName = 'ahadith_alzakah_instance.lock';
  static HttpServer? _server;
  static File? _lockFile;

  static Future<File> _getLockFile() async {
    if (_lockFile != null) return _lockFile!;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _lockFile = File('${dir.path}/$_lockFileName');
    return _lockFile!;
  }

  /// Starts the server for the primary instance.
  /// Returns `true` if this instance becomes the primary, `false` otherwise.
  static Future<bool> startServer(Function(String) onMessageReceived) async {
    final lockFile = await _getLockFile();

    if (await lockFile.exists()) {
      debugPrint('Lock file found. Verifying primary instance...');
      try {
        final lockData = json.decode(await lockFile.readAsString());
        final port = lockData['port'] as int;

        // Try to connect to the existing server to see if it's alive
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 2);
        final request = await client.post(InternetAddress.loopbackIPv4.host, port, '/ping');
        request.write('ping');
        final response = await request.close();
        client.close();

        if (response.statusCode == HttpStatus.ok) {
          debugPrint('Primary instance is alive. This is a secondary instance.');
          return false; // It's a secondary instance
        }
        throw Exception('Primary instance responded with status ${response.statusCode}');
      } catch (e) {
        debugPrint('Primary instance is not responding. Deleting stale lock file. Error: $e');
        await lockFile.delete();
      }
    }

    // This instance will become the primary
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      await lockFile.writeAsString(json.encode({'port': _server!.port}));

      _server!.listen((request) async {
        if (request.method == 'POST') {
          final content = await utf8.decodeStream(request);
          if (content != 'ping') {
            onMessageReceived(content);
          }
        }
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      });

      debugPrint('This instance became the primary. Server on port ${_server!.port}');
      return true; // Became primary
    } catch (e) {
      debugPrint('Failed to start primary instance server: $e');
      await stopServer();
      return false;
    }
  }

  /// Sends a message from a secondary instance to the primary one.
  static Future<bool> sendMessage(String message) async {
    final lockFile = await _getLockFile();
    if (!await lockFile.exists()) {
      debugPrint('No primary instance found (lock file does not exist).');
      return false;
    }

    try {
      final lockData = json.decode(await lockFile.readAsString());
      final port = lockData['port'] as int;

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.post(InternetAddress.loopbackIPv4.host, port, '/');
      request.headers.contentType = ContentType.json;
      request.write(message);
      final response = await request.close();
      client.close();

      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('Error sending message. Primary instance might have crashed. Error: $e');
      return false;
    }
  }

  /// Stops the server and cleans up the lock file.
  static Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    final lockFile = await _getLockFile();
    if (await lockFile.exists()) {
      try {
        await lockFile.delete();
      } catch (e) {
        debugPrint('Failed to delete lock file: $e');
      }
    }
    debugPrint('Primary instance server stopped and lock file deleted.');
  }
}