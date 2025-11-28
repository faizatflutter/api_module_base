import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Used to check internet connectivity
class ConnectivityManager {
  static final ConnectivityManager _singleton = ConnectivityManager._internal();

  factory ConnectivityManager() {
    return _singleton;
  }

  ConnectivityManager._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> checkInternet() async {
    try {
      List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } on PlatformException catch (e) {
      debugPrint('Could not check connectivity status: $e');
      return false;
    }
  }
}

