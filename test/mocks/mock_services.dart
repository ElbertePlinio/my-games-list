import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/session_reset_service.dart';

class MockLocalStorageService implements LocalStorageService {
  final Map<String, dynamic> _storage = {};
  final List<Map<String, dynamic>> setStringCallHistory = [];
  final List<Map<String, dynamic>> setBoolCallHistory = [];
  final List<Map<String, dynamic>> setStringListCallHistory = [];
  final List<String> removeCallHistory = [];

  String? _stringReturn;
  bool? _boolReturn;
  int? _intReturn;
  double? _doubleReturn;
  List<String>? _stringListReturn;

  void setStringReturn(String? value) => _stringReturn = value;
  void setBoolReturn(bool? value) => _boolReturn = value;
  void setIntReturn(int? value) => _intReturn = value;
  void setDoubleReturn(double? value) => _doubleReturn = value;
  void setStringListReturn(List<String>? value) => _stringListReturn = value;

  @override
  Future<String?> getString(String key) async {
    if (_stringReturn != null) {
      final result = _stringReturn;
      _stringReturn = null; // Reset after use
      return result;
    }
    return _storage[key] as String?;
  }

  @override
  Future<bool?> getBool(String key) async {
    if (_boolReturn != null) {
      final result = _boolReturn;
      _boolReturn = null; // Reset after use
      return result;
    }
    return _storage[key] as bool?;
  }

  @override
  Future<int?> getInt(String key) async {
    if (_intReturn != null) {
      final result = _intReturn;
      _intReturn = null; // Reset after use
      return result;
    }
    return _storage[key] as int?;
  }

  @override
  Future<double?> getDouble(String key) async {
    if (_doubleReturn != null) {
      final result = _doubleReturn;
      _doubleReturn = null; // Reset after use
      return result;
    }
    return _storage[key] as double?;
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    if (_stringListReturn != null) {
      final result = _stringListReturn;
      _stringListReturn = null; // Reset after use
      return result;
    }
    return _storage[key] as List<String>?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    setStringCallHistory.add({'key': key, 'value': value});
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    setBoolCallHistory.add({'key': key, 'value': value});
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    setStringListCallHistory.add({'key': key, 'value': value});
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    removeCallHistory.add(key);
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Set<String>> getKeys() async {
    return _storage.keys.toSet();
  }

  void reset() {
    _storage.clear();
    setStringCallHistory.clear();
    setBoolCallHistory.clear();
    setStringListCallHistory.clear();
    removeCallHistory.clear();
    _stringReturn = null;
    _boolReturn = null;
    _intReturn = null;
    _doubleReturn = null;
    _stringListReturn = null;
  }
}

/// Fake [SessionResetService] for tests — records whether teardown was invoked.
class FakeSessionResetService implements SessionResetService {
  bool teardownCalled = false;

  @override
  Future<void> teardownSession() async {
    teardownCalled = true;
  }
}
