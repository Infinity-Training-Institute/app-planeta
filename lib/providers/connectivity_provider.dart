import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();

  ConnectivityProvider() {
    _checkInitialConnection(); // Verifica el estado inicial
    _connectivity.onConnectivityChanged.listen((connectivityList) {
      _connectivityStatus =
          connectivityList.isNotEmpty
              ? connectivityList.first
              : ConnectivityResult.none;
      notifyListeners();
    });
  }

  Future<void> _checkInitialConnection() async {
    final status = await _connectivity.checkConnectivity();
    _connectivityStatus = status as ConnectivityResult;
    notifyListeners();
  }

  bool get isConnected => _connectivityStatus != ConnectivityResult.none;
}
