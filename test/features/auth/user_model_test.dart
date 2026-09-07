import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/auth/user_model.dart';

void main() {
  group('User Model', () {
    const testUser = User(
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
    );

    test('should create User with required properties', () {
      expect(testUser.id, equals('123'));
      expect(testUser.email, equals('test@example.com'));
      expect(testUser.name, equals('Test User'));
    });

    test('should create User from JSON', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'name': 'Test User',
      };

      final user = User.fromJson(json);

      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(user.name, equals('Test User'));
    });

    test('should convert User to JSON', () {
      final json = testUser.toJson();

      expect(json['id'], equals('123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['name'], equals('Test User'));
    });

    test('should create copy with updated properties', () {
      final updatedUser = testUser.copyWith(
        name: 'Updated Name',
        email: 'updated@example.com',
      );

      expect(updatedUser.id, equals('123')); // unchanged
      expect(updatedUser.email, equals('updated@example.com')); // changed
      expect(updatedUser.name, equals('Updated Name')); // changed
    });

    test('should implement equality correctly', () {
      const user1 = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      const user2 = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      const user3 = User(
        id: '456',
        email: 'other@example.com',
        name: 'Other User',
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('should have consistent hashCode', () {
      const user1 = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      const user2 = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('should have meaningful toString', () {
      final userString = testUser.toString();

      expect(userString, contains('User'));
      expect(userString, contains('123'));
      expect(userString, contains('test@example.com'));
      expect(userString, contains('Test User'));
    });
  });
}
