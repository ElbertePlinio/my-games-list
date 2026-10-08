import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

enum ConnectedAccountsStatus { initial, loading, ready, failure }

enum LinkStatus { idle, submitting, success, failure }

/// One-off outcome the screen shows as a snackbar.
enum AccountNoticeType {
  linked,
  unlinked,
  syncStarted,
  syncFailed,
  unlinkFailed,
  syncFinished,

  /// A refresh failed while the list stayed on screen. Has no provider.
  refreshFailed,
}

class AccountNotice extends Equatable {
  const AccountNotice({
    required this.id,
    required this.type,
    this.provider,
    this.errorKind,
  });

  /// Increments for each notice so equal notices still fire listeners.
  final int id;
  final AccountNoticeType type;
  final GameProvider? provider;
  final IntegrationErrorKind? errorKind;

  @override
  List<Object?> get props => [id, type, provider, errorKind];
}

class ConnectedAccountsState extends Equatable {
  const ConnectedAccountsState({
    this.status = ConnectedAccountsStatus.initial,
    this.providers = const [],
    this.errorKind,
    this.linkStatus = LinkStatus.idle,
    this.linkErrorKind,
    this.busyProviders = const {},
    this.notice,
  });

  final ConnectedAccountsStatus status;
  final List<LinkedProvider> providers;
  final IntegrationErrorKind? errorKind;
  final LinkStatus linkStatus;
  final IntegrationErrorKind? linkErrorKind;

  /// Providers with a sync start or unlink request in flight.
  final Set<GameProvider> busyProviders;
  final AccountNotice? notice;

  bool get anySyncing => providers.any((p) => p.isSyncing);

  LinkedProvider? providerFor(GameProvider provider) {
    for (final p in providers) {
      if (p.provider == provider) return p;
    }
    return null;
  }

  ConnectedAccountsState copyWith({
    ConnectedAccountsStatus? status,
    List<LinkedProvider>? providers,
    IntegrationErrorKind? Function()? errorKind,
    LinkStatus? linkStatus,
    IntegrationErrorKind? Function()? linkErrorKind,
    Set<GameProvider>? busyProviders,
    AccountNotice? notice,
  }) {
    return ConnectedAccountsState(
      status: status ?? this.status,
      providers: providers ?? this.providers,
      errorKind: errorKind != null ? errorKind() : this.errorKind,
      linkStatus: linkStatus ?? this.linkStatus,
      linkErrorKind: linkErrorKind != null
          ? linkErrorKind()
          : this.linkErrorKind,
      busyProviders: busyProviders ?? this.busyProviders,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [
    status,
    providers,
    errorKind,
    linkStatus,
    linkErrorKind,
    busyProviders,
    notice,
  ];
}

/// Linked accounts: load, link, sync with polling, and unlink.
///
/// While any provider reports `syncing`, the cubit polls the list every
/// [pollInterval]. Polling stops when no sync is running or the cubit closes
/// with its route.
class ConnectedAccountsCubit extends Cubit<ConnectedAccountsState> {
  ConnectedAccountsCubit({
    required IntegrationsRepository repository,
    this.pollInterval = const Duration(seconds: 4),
  }) : _repository = repository,
       super(const ConnectedAccountsState());

  final IntegrationsRepository _repository;
  final Duration pollInterval;
  Timer? _pollTimer;
  bool _polling = false;
  int _noticeId = 0;

  /// Bumped on each local account change, so a list request that started
  /// earlier cannot overwrite the newer state.
  int _generation = 0;

  /// True while the poll timer is active. Exposed for tests.
  bool get isPolling => _pollTimer?.isActive ?? false;

  /// Loads the list. A refresh keeps the current list on screen.
  Future<void> load() async {
    if (state.providers.isEmpty) {
      emit(
        state.copyWith(
          status: ConnectedAccountsStatus.loading,
          errorKind: () => null,
        ),
      );
    }
    final generation = _generation;
    try {
      final providers = await _repository.getLinkedAccounts();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ConnectedAccountsStatus.ready,
          providers: generation == _generation ? providers : null,
        ),
      );
      _updatePolling();
    } catch (e) {
      if (!isClosed) _onLoadFailed(IntegrationErrorKind.from(e));
    }
  }

  /// A failed first load shows the error view. A failed refresh keeps the
  /// list and reports a notice instead.
  void _onLoadFailed(IntegrationErrorKind kind) {
    if (state.providers.isEmpty) {
      emit(
        state.copyWith(
          status: ConnectedAccountsStatus.failure,
          errorKind: () => kind,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: ConnectedAccountsStatus.ready,
        notice: _notice(AccountNoticeType.refreshFailed, null, kind),
      ),
    );
  }

  /// Clears the previous link result before the sheet opens.
  void resetLink() => emit(
    state.copyWith(linkStatus: LinkStatus.idle, linkErrorKind: () => null),
  );

  Future<void> link(GameProvider provider, String identifier) async {
    if (state.linkStatus == LinkStatus.submitting) return;
    if (identifier.trim().isEmpty) {
      emit(
        state.copyWith(
          linkStatus: LinkStatus.failure,
          linkErrorKind: () => IntegrationErrorKind.invalidIdentifier,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        linkStatus: LinkStatus.submitting,
        linkErrorKind: () => null,
      ),
    );
    try {
      final account = await _repository.link(provider, identifier);
      if (isClosed) return;
      _generation++;
      emit(
        state.copyWith(
          linkStatus: LinkStatus.success,
          providers: _replace(provider, account),
          notice: _notice(AccountNoticeType.linked, provider),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          linkStatus: LinkStatus.failure,
          linkErrorKind: () => IntegrationErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> sync(GameProvider provider, {bool importLibrary = false}) async {
    if (state.busyProviders.contains(provider)) return;
    emit(state.copyWith(busyProviders: {...state.busyProviders, provider}));
    try {
      await _repository.sync(provider, importLibrary: importLibrary);
      if (isClosed) return;
      _generation++;
      final current = state.providerFor(provider)?.account;
      emit(
        state.copyWith(
          busyProviders: {...state.busyProviders}..remove(provider),
          providers: current == null
              ? null
              : _replace(
                  provider,
                  current.copyWith(syncStatus: SyncStatus.syncing),
                ),
          notice: _notice(AccountNoticeType.syncStarted, provider),
        ),
      );
      _updatePolling();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          busyProviders: {...state.busyProviders}..remove(provider),
          notice: _notice(
            AccountNoticeType.syncFailed,
            provider,
            IntegrationErrorKind.from(e),
          ),
        ),
      );
    }
  }

  Future<void> unlink(GameProvider provider) async {
    if (state.busyProviders.contains(provider)) return;
    emit(state.copyWith(busyProviders: {...state.busyProviders, provider}));
    try {
      await _repository.unlink(provider);
      if (isClosed) return;
      _generation++;
      emit(
        state.copyWith(
          busyProviders: {...state.busyProviders}..remove(provider),
          providers: _replace(provider, null),
          notice: _notice(AccountNoticeType.unlinked, provider),
        ),
      );
      _updatePolling();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          busyProviders: {...state.busyProviders}..remove(provider),
          notice: _notice(
            AccountNoticeType.unlinkFailed,
            provider,
            IntegrationErrorKind.from(e),
          ),
        ),
      );
    }
  }

  /// One silent refresh while a sync runs. Errors keep the last list, and
  /// a response older than the last account change is dropped.
  Future<void> poll() async {
    if (_polling || isClosed) return;
    _polling = true;
    final generation = _generation;
    try {
      final before = {
        for (final p in state.providers)
          if (p.isSyncing) p.provider,
      };
      final providers = await _repository.getLinkedAccounts();
      if (isClosed || generation != _generation) return;
      final finished = [
        for (final p in providers)
          if (before.contains(p.provider) && !p.isSyncing) p.provider,
      ];
      emit(
        state.copyWith(
          providers: providers,
          notice: finished.isEmpty
              ? null
              : _notice(AccountNoticeType.syncFinished, finished.first),
        ),
      );
    } catch (_) {
      // Keep polling; a transient failure should not end the sync view.
    } finally {
      _polling = false;
      if (!isClosed) _updatePolling();
    }
  }

  void _updatePolling() {
    if (state.anySyncing) {
      _pollTimer ??= Timer.periodic(pollInterval, (_) => poll());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  List<LinkedProvider> _replace(GameProvider provider, LinkedAccount? account) {
    return [
      for (final p in state.providers)
        p.provider == provider ? p.withAccount(account) : p,
    ];
  }

  AccountNotice _notice(
    AccountNoticeType type,
    GameProvider? provider, [
    IntegrationErrorKind? kind,
  ]) => AccountNotice(
    id: ++_noticeId,
    type: type,
    provider: provider,
    errorKind: kind,
  );

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }
}
