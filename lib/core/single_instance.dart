import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SingleInstance {
  static const int _port = 53421;
  static ServerSocket? _server;
  static final StreamController<String> _controller = StreamController<String>.broadcast();

  /// Stream of incoming messages (JSON strings) from secondary instances.
  static Stream<String> get messages => _controller.stream;

  /// Try to become primary by binding to loopback port. Returns true if this
  /// process is the primary instance. If false, another instance is already running.
  static Future<bool> startServer() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _server!.listen((Socket client) {
        final buffer = <int>[];
        client.listen((data) {
          buffer.addAll(data);
        }, onDone: () {
          try {
            final s = utf8.decode(buffer);
            _controller.add(s);
          } catch (_) {}
          client.destroy();
        }, onError: (_) {
          client.destroy();
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send a JSON string to the primary instance. Best-effort, silence errors.
  static Future<void> sendMessage(String message) async {
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, _port, timeout: const Duration(seconds: 2));
      socket.add(utf8.encode(message));
      await socket.flush();
      socket.destroy();
    } catch (e) {
      // ignore
    }
  }

  static Future<void> stopServer() async {
    try {
      await _server?.close();
    } catch (_) {}
    try {
      await _controller.close();
    } catch (_) {}
  }
}
