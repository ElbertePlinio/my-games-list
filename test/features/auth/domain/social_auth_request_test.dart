import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/auth/domain/social_auth_request.dart';
import 'package:picklog/features/legal/legal_constants.dart';

void main() {
  group('SocialAuthRequest', () {
    test('toJson serializes consent version under consent_version key', () {
      const request = SocialAuthRequest(
        provider: 'google',
        firebaseIdToken: 'firebase-token',
        consentVersion: kConsentVersion,
      );

      final json = request.toJson();

      expect(json['provider'], 'google');
      expect(json['firebase_id_token'], 'firebase-token');
      expect(json.containsKey('consent_version'), isTrue);
      expect(json['consent_version'], kConsentVersion);
    });
  });
}
