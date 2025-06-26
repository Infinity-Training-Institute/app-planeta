import 'package:flutter/widgets.dart';

class UserProvider with ChangeNotifier {
  String _username = '';

  String get username => _username;

  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }
}

class StandProvider with ChangeNotifier {
  String _stand = '';

  String get stand => _stand;

  void setStand(String value) {
    _stand = value;
    notifyListeners();
  }
}