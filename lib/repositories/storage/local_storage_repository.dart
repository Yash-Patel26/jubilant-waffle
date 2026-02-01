import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ILocalStorageRepository {
  Future<void> initialize();
  
  // Secure Storage
  Future<void> setSecureString(String key, String value);
  Future<String?> getSecureString(String key);
  Future<void> removeSecureString(String key);
  Future<void> clearSecureStorage();
  
  // Regular Storage
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> setBool(String key, bool value);
  bool? getBool(String key);
  Future<void> setInt(String key, int value);
  int? getInt(String key);
  Future<void> setDouble(String key, double value);
  double? getDouble(String key);
  Future<void> setStringList(String key, List<String> value);
  List<String>? getStringList(String key);
  
  // JSON
  Future<void> setJson(String key, Map<String, dynamic> value);
  Map<String, dynamic>? getJson(String key);
  
  // Utils
  Future<void> remove(String key);
  Future<void> clear();
  bool containsKey(String key);
  Set<String> getKeys();
}

class SharedPreferencesLocalStorageRepository implements ILocalStorageRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _preferences;

  @override
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  @override
  Future<void> setSecureString(String key, String value) async => await _secureStorage.write(key: key, value: value);

  @override
  Future<String?> getSecureString(String key) async => await _secureStorage.read(key: key);

  @override
  Future<void> removeSecureString(String key) async => await _secureStorage.delete(key: key);

  @override
  Future<void> clearSecureStorage() async => await _secureStorage.deleteAll();

  @override
  Future<void> setString(String key, String value) async => await _preferences?.setString(key, value);

  @override
  String? getString(String key) => _preferences?.getString(key);

  @override
  Future<void> setBool(String key, bool value) async => await _preferences?.setBool(key, value);

  @override
  bool? getBool(String key) => _preferences?.getBool(key);

  @override
  Future<void> setInt(String key, int value) async => await _preferences?.setInt(key, value);

  @override
  int? getInt(String key) => _preferences?.getInt(key);

  @override
  Future<void> setDouble(String key, double value) async => await _preferences?.setDouble(key, value);

  @override
  double? getDouble(String key) => _preferences?.getDouble(key);

  @override
  Future<void> setStringList(String key, List<String> value) async => await _preferences?.setStringList(key, value);

  @override
  List<String>? getStringList(String key) => _preferences?.getStringList(key);

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await setString(key, jsonString);
  }

  @override
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> remove(String key) async => await _preferences?.remove(key);

  @override
  Future<void> clear() async => await _preferences?.clear();

  @override
  bool containsKey(String key) => _preferences?.containsKey(key) ?? false;

  @override
  Set<String> getKeys() => _preferences?.getKeys() ?? <String>{};
}

final localStorageRepositoryProvider = Provider<ILocalStorageRepository>((ref) {
  // Note: initialize() must be called before usage. 
  // In main.dart, we should ensure it's initialized.
  return SharedPreferencesLocalStorageRepository();
});
