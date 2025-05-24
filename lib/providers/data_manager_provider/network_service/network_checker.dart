import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class NetworkChecker {
  final Logger _logger = Logger();

  Future<bool> isConnectedToInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return false;
      final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('DNS lookup timed out'),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.e('Internet check failed: $e');
      return false;
    }
  }
}