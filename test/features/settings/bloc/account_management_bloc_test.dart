import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/settings/bloc/account_management_bloc.dart';
import 'package:picklog/features/settings/bloc/account_management_event.dart';
import 'package:picklog/features/settings/bloc/account_management_state.dart';
import 'package:picklog/features/settings/services/account_export_saver.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeAccountExportSaver implements AccountExportSaver {
  String? savedFileName;
  String? savedJson;
  bool shouldThrow = false;

  @override
  Future<void> save({
    required String fileName,
    required String json,
    Rect? sharePositionOrigin,
  }) async {
    if (shouldThrow) throw Exception('save failed');
    savedFileName = fileName;
    savedJson = json;
  }
}

void main() {
  late MockAuthRepository repository;
  late FakeAccountExportSaver saver;

  setUp(() {
    repository = MockAuthRepository();
    saver = FakeAccountExportSaver();
  });

  AccountManagementBloc build() =>
      AccountManagementBloc(authRepository: repository, exportSaver: saver);

  group('AccountManagementBloc export', () {
    blocTest<AccountManagementBloc, AccountManagementState>(
      'fetches data and delivers it, emitting loading then success',
      build: () {
        when(() => repository.exportData()).thenAnswer((_) async => '{"a":1}');
        return build();
      },
      act: (bloc) => bloc.add(const AccountManagementExportRequested()),
      expect: () => const [
        AccountManagementState(exportStatus: AccountActionStatus.loading),
        AccountManagementState(exportStatus: AccountActionStatus.success),
      ],
      verify: (_) {
        verify(() => repository.exportData()).called(1);
        expect(saver.savedJson, '{"a":1}');
        expect(saver.savedFileName, 'mygameslist-export.json');
      },
    );

    blocTest<AccountManagementBloc, AccountManagementState>(
      'emits failure when the export request throws',
      build: () {
        when(() => repository.exportData()).thenThrow(Exception('network'));
        return build();
      },
      act: (bloc) => bloc.add(const AccountManagementExportRequested()),
      expect: () => [
        const AccountManagementState(exportStatus: AccountActionStatus.loading),
        isA<AccountManagementState>()
            .having(
              (s) => s.exportStatus,
              'exportStatus',
              AccountActionStatus.failure,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );

    blocTest<AccountManagementBloc, AccountManagementState>(
      'emits failure when saving the export throws',
      build: () {
        when(() => repository.exportData()).thenAnswer((_) async => '{}');
        saver.shouldThrow = true;
        return build();
      },
      act: (bloc) => bloc.add(const AccountManagementExportRequested()),
      expect: () => [
        const AccountManagementState(exportStatus: AccountActionStatus.loading),
        isA<AccountManagementState>().having(
          (s) => s.exportStatus,
          'exportStatus',
          AccountActionStatus.failure,
        ),
      ],
    );
  });

  group('AccountManagementBloc delete', () {
    blocTest<AccountManagementBloc, AccountManagementState>(
      'emits loading then success when deletion succeeds',
      build: () {
        when(() => repository.deleteAccount()).thenAnswer((_) async {});
        return build();
      },
      act: (bloc) => bloc.add(const AccountManagementDeleteRequested()),
      expect: () => const [
        AccountManagementState(deleteStatus: AccountActionStatus.loading),
        AccountManagementState(deleteStatus: AccountActionStatus.success),
      ],
      verify: (_) => verify(() => repository.deleteAccount()).called(1),
    );

    blocTest<AccountManagementBloc, AccountManagementState>(
      'emits failure when deletion throws',
      build: () {
        when(() => repository.deleteAccount()).thenThrow(Exception('denied'));
        return build();
      },
      act: (bloc) => bloc.add(const AccountManagementDeleteRequested()),
      expect: () => [
        const AccountManagementState(deleteStatus: AccountActionStatus.loading),
        isA<AccountManagementState>()
            .having(
              (s) => s.deleteStatus,
              'deleteStatus',
              AccountActionStatus.failure,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );
  });
}
