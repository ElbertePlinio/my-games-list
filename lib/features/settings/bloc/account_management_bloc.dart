import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/settings/bloc/account_management_event.dart';
import 'package:picklog/features/settings/bloc/account_management_state.dart';
import 'package:picklog/features/settings/services/account_export_saver.dart';

/// Handles the LGPD account actions: exporting the user's data and permanently
/// deleting the account. Deletion only clears state on the backend; the local
/// session teardown is dispatched by the UI via AuthBloc on success.
class AccountManagementBloc
    extends Bloc<AccountManagementEvent, AccountManagementState> {
  AccountManagementBloc({
    required AuthRepository authRepository,
    AccountExportSaver? exportSaver,
  }) : _authRepository = authRepository,
       _exportSaver = exportSaver ?? AccountExportSaver(),
       super(const AccountManagementState()) {
    on<AccountManagementExportRequested>(_onExportRequested);
    on<AccountManagementDeleteRequested>(_onDeleteRequested);
  }

  final AuthRepository _authRepository;
  final AccountExportSaver _exportSaver;

  static const _exportFileName = 'mygameslist-export.json';

  Future<void> _onExportRequested(
    AccountManagementExportRequested event,
    Emitter<AccountManagementState> emit,
  ) async {
    emit(state.copyWith(exportStatus: AccountActionStatus.loading));
    try {
      final json = await _authRepository.exportData();
      await _exportSaver.save(
        fileName: _exportFileName,
        json: json,
        sharePositionOrigin: event.sharePositionOrigin,
      );
      emit(state.copyWith(exportStatus: AccountActionStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          exportStatus: AccountActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    AccountManagementDeleteRequested event,
    Emitter<AccountManagementState> emit,
  ) async {
    emit(state.copyWith(deleteStatus: AccountActionStatus.loading));
    try {
      await _authRepository.deleteAccount();
      emit(state.copyWith(deleteStatus: AccountActionStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          deleteStatus: AccountActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
