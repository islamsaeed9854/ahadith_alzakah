import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Ensures that only a single instance of the application is running
/// by using a lock file to store the communication port.
class SingleInstance {
  static const _lockFileName = 'ahadith_alzakah_instance.lock';
  static HttpServer? _server;
  static File? _lockFile;

  static final StreamController<String> _messagesController = StreamController.broadcast();
  static Stream<String> get messages => _messagesController.stream;

  static Future<File> _getLockFile() async {
    if (_lockFile != null) return _lockFile!;
    // Use a reliable directory for application data
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _lockFile = File('${dir.path}/$_lockFileName');
    return _lockFile!;
  }

  /// Tries to start the server and create a lock file.
  /// Returns `true` if it successfully becomes the primary instance.
  /// Returns `false` if another instance is already running.
  static Future<bool> startServer() async {
    final lockFile = await _getLockFile();

    if (await lockFile.exists()) {
      debugPrint('Lock file found, another instance might be running.');
      return false; // Found a lock file, so this is a secondary instance.
    }

    try {
      // Bind to port 0 to let the OS choose an available port.
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      
      // Write the chosen port to the lock file.
      await lockFile.writeAsString(json.encode({'port': _server!.port}));

      _server!.listen((request) async {
        if (request.method == 'POST') {
          final content = await utf8.decodeStream(request);
          _messagesController.add(content);
        }
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      });

      debugPrint('Primary instance server started on port ${_server!.port}');
      return true;
    } catch (e) {
      debugPrint('Failed to start primary instance server: $e');
      await stopServer(); // Clean up any partial state.
      return false;
    }
  }

  /// Sends a message to the primary instance.
  /// Reads the port from the lock file.
  /// Returns `true` on success, `false` on failure.
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
      final request = await client.post(InternetAddress.loopbackIPv4.host, port, '/');
      request.headers.contentType = ContentType.json;
      request.write(message);
      final response = await request.close();
      client.close();

      if (response.statusCode == HttpStatus.ok) {
        debugPrint('Message sent successfully to primary instance.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending message. Primary instance might have crashed. Deleting stale lock file. Error: $e');
      // If we can't connect, the primary instance may have crashed.
      // Delete the stale lock file so a new primary can start.
      await lockFile.delete();
      return false;
    }
  }

  /// Stops the server and deletes the lock file.
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
    // Do not close the controller here, as it might be needed if the app restarts.
    debugPrint('Primary instance server stopped and lock file deleted.');
  }
}