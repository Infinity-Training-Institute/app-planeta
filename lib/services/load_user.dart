import 'package:app_planeta/infrastructure/local_db/app_database.dart';

class LoadUser {
  // Method to load user data from the database
  Future<List<Map<String, dynamic>>> loadUser() async {
    try {
      // Fetch user data from the database
      final data = await AppDatabase.getUsuarios();
      return data;
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }
}
