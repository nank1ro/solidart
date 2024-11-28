import 'dart:io';

import 'package:flutter/foundation.dart';

/// Connectivity represents a singleton helper for retrieving connectivity
/// from the internet
class Connectivity {
  static final instance = Connectivity._internal();

  // internal constructor
  Connectivity._internal();

  /// Returns true if connected, false otherwise
  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      debugPrint('Unable to read connectivity from internet, $e');
      return false;
    }
  }
}
