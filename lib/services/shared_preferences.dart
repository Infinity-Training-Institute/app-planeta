import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();
  late SharedPreferences _prefs;

  SharedPreferencesService._internal();

  factory SharedPreferencesService() => _instance;

  /// Llama esto una vez (por ejemplo en `main`) antes de usar el servicio
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Guarda un booleano
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Obtiene un booleano con valor por defecto si no existe
  bool getBool(String key, {bool defaultValue = true}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// Guarda múltiples valores booleanos
  Future<void> setMultipleBools(Map<String, bool> values) async {
    for (final entry in values.entries) {
      await setBool(entry.key, entry.value);
    }
  }

  /// Obtiene múltiples valores booleanos
  Map<String, bool> getMultipleBools(
    List<String> keys, {
    bool defaultValue = true,
  }) {
    final Map<String, bool> result = {};
    for (final key in keys) {
      result[key] = getBool(key, defaultValue: defaultValue);
    }
    return result;
  }

  /// Opcional: eliminar un valor
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Opcional: limpiar todo
  Future<void> clear() async {
    await _prefs.clear();
  }
}
