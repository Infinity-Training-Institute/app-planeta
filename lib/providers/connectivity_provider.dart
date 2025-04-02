import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();

  ConnectivityProvider() {
    _checkInitialConnection();
    _connectivity.onConnectivityChanged.listen((connectivityList) {
      _connectivityStatus =
          connectivityList.isNotEmpty
              ? connectivityList.first
              : ConnectivityResult.none;
      notifyListeners();
    });
  }

  Future<void> _checkInitialConnection() async {
    final List<ConnectivityResult> statusList =
        await _connectivity.checkConnectivity();
    _connectivityStatus =
        statusList.isNotEmpty ? statusList.first : ConnectivityResult.none;
    notifyListeners();
  }

  bool get isConnected => _connectivityStatus != ConnectivityResult.none;
}
