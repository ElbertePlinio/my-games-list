import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/data/services/storage/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesService', () {
    late SharedPreferencesService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = SharedPreferencesService(prefs);
    });

    test('should implement LocalStorageService', () {
      expect(service, isA<LocalStorageService>());
    });

    group('string operations', () {
      test('should store and retrieve string values', () async {
        const key = 'test_string';
        const value = 'test_value';

        final result = await service.setString(key, value);
        expect(result, isTrue);

        final retrieved = await service.getString(key);
        expect(retrieved, equals(value));
      });

      test('should return null for non-existent string key', () async {
        final result = await service.getString('non_existent');
        expect(result, isNull);
      });
    });

    group('bool operations', () {
      test('should store and retrieve bool values', () async {
        const key = 'test_bool';
        const value = true;

        final result = await service.setBool(key, value);
        expect(result, isTrue);

        final retrieved = await service.getBool(key);
        expect(retrieved, equals(value));
      });

      test('should return null for non-existent bool key', () async {
        final result = await service.getBool('non_existent');
        expect(result, isNull);
      });
    });

    group('int operations', () {
      test('should store and retrieve int values', () async {
        const key = 'test_int';
        const value = 42;

        final result = await service.setInt(key, value);
        expect(result, isTrue);

        final retrieved = await service.getInt(key);
        expect(retrieved, equals(value));
      });
    });

    group('double operations', () {
      test('should store and retrieve double values', () async {
        const key = 'test_double';
        const value = 3.14;

        final result = await service.setDouble(key, value);
        expect(result, isTrue);

        final retrieved = await service.getDouble(key);
        expect(retrieved, equals(value));
      });
    });

    group('string list operations', () {
      test('should store and retrieve string list values', () async {
        const key = 'test_list';
        const value = ['item1', 'item2', 'item3'];

        final result = await service.setStringList(key, value);
        expect(result, isTrue);

        final retrieved = await service.getStringList(key);
        expect(retrieved, equals(value));
      });
    });

    group('key operations', () {
      test('should check if key exists', () async {
        const key = 'test_key';
        const value = 'test_value';

        expect(await service.containsKey(key), isFalse);

        await service.setString(key, value);
        expect(await service.containsKey(key), isTrue);
      });

      test('should get all keys', () async {
        await service.setString('key1', 'value1');
        await service.setString('key2', 'value2');

        final keys = await service.getKeys();
        expect(keys, contains('key1'));
        expect(keys, contains('key2'));
      });

      test('should remove key', () async {
        const key = 'test_key';
        await service.setString(key, 'value');

        expect(await service.containsKey(key), isTrue);

        final result = await service.remove(key);
        expect(result, isTrue);
        expect(await service.containsKey(key), isFalse);
      });

      test('should clear all keys', () async {
        await service.setString('key1', 'value1');
        await service.setString('key2', 'value2');

        final result = await service.clear();
        expect(result, isTrue);

        final keys = await service.getKeys();
        expect(keys, isEmpty);
      });
    });
  });
}
