import 'package:equatable/equatable.dart';

/// Gaming services a user can link with a public identifier.
enum GameProvider {
  steam('steam'),
  xbox('xbox'),
  retroAchievements('retroachievements'),
  psn('psn');

  const GameProvider(this.apiValue);

  final String apiValue;

  static GameProvider? fromApi(String? value) {
    for (final p in values) {
      if (p.apiValue == value) return p;
    }
    return null;
  }
}

enum SyncStatus {
  idle,
  syncing,
  ok,
  error;

  static SyncStatus fromApi(String? value) => switch (value) {
    'syncing' => SyncStatus.syncing,
    'ok' => SyncStatus.ok,
    'error' => SyncStatus.error,
    _ => SyncStatus.idle,
  };
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String? _nonEmpty(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

/// A linked account on one provider.
class LinkedAccount extends Equatable {
  const LinkedAccount({
    required this.externalId,
    required this.displayName,
    required this.linkedAt,
    required this.syncStatus,
    this.avatarUrl,
    this.profileUrl,
    this.lastSyncedAt,
    this.syncError,
  });

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      externalId: json['external_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: _nonEmpty(json['avatar_url']),
      profileUrl: _nonEmpty(json['profile_url']),
      linkedAt:
          _date(json['linked_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastSyncedAt: _date(json['last_synced_at']),
      syncStatus: SyncStatus.fromApi(json['sync_status'] as String?),
      syncError: _nonEmpty(json['sync_error']),
    );
  }

  final String externalId;
  final String displayName;
  final String? avatarUrl;
  final String? profileUrl;
  final DateTime linkedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final String? syncError;

  LinkedAccount copyWith({SyncStatus? syncStatus}) => LinkedAccount(
    externalId: externalId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    profileUrl: profileUrl,
    linkedAt: linkedAt,
    lastSyncedAt: lastSyncedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError,
  );

  @override
  List<Object?> get props => [
    externalId,
    displayName,
    avatarUrl,
    profileUrl,
    linkedAt,
    lastSyncedAt,
    syncStatus,
    syncError,
  ];
}

/// One provider row from `GET /users/me/linked-accounts`.
class LinkedProvider extends Equatable {
  const LinkedProvider({
    required this.provider,
    required this.available,
    required this.experimental,
    this.account,
  });

  factory LinkedProvider.fromJson(Map<String, dynamic> json) {
    final account = json['account'];
    final linked = json['linked'] as bool? ?? false;
    return LinkedProvider(
      provider: GameProvider.fromApi(json['provider'] as String?)!,
      available: json['available'] as bool? ?? false,
      experimental: json['experimental'] as bool? ?? false,
      account: linked && account is Map<String, dynamic>
          ? LinkedAccount.fromJson(account)
          : null,
    );
  }

  final GameProvider provider;
  final bool available;
  final bool experimental;
  final LinkedAccount? account;

  bool get isLinked => account != null;
  bool get isSyncing => account?.syncStatus == SyncStatus.syncing;

  LinkedProvider withAccount(LinkedAccount? account) => LinkedProvider(
    provider: provider,
    available: available,
    experimental: experimental,
    account: account,
  );

  @override
  List<Object?> get props => [provider, available, experimental, account];

  /// Parses the list, skipping providers this app version does not know.
  static List<LinkedProvider> listFromJson(Map<String, dynamic> json) {
    final raw = json['providers'] as List<dynamic>? ?? const [];
    return [
      for (final p in raw.cast<Map<String, dynamic>>())
        if (GameProvider.fromApi(p['provider'] as String?) != null)
          LinkedProvider.fromJson(p),
    ];
  }
}

/// Per-game achievement progress.
class GameProgress extends Equatable {
  const GameProgress({
    required this.provider,
    required this.externalGameId,
    required this.name,
    required this.unlocked,
    required this.total,
    required this.completionPct,
    this.igdbId,
    this.coverUrl,
    this.playtimeMinutes,
    this.lastPlayedAt,
  });

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      provider:
          GameProvider.fromApi(json['provider'] as String?) ??
          GameProvider.steam,
      externalGameId: json['external_game_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      igdbId: (json['igdb_id'] as num?)?.toInt(),
      coverUrl: _nonEmpty(json['cover_url']),
      unlocked: (json['unlocked'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      completionPct: (json['completion_pct'] as num?)?.toDouble() ?? 0,
      playtimeMinutes: (json['playtime_minutes'] as num?)?.toInt(),
      lastPlayedAt: _date(json['last_played_at']),
    );
  }

  final GameProvider provider;
  final String externalGameId;
  final String name;
  final int? igdbId;
  final String? coverUrl;
  final int unlocked;
  final int total;

  /// 0-100.
  final double completionPct;
  final int? playtimeMinutes;
  final DateTime? lastPlayedAt;

  /// 0-1 for progress bars.
  double get fraction => (completionPct / 100).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [
    provider,
    externalGameId,
    name,
    igdbId,
    coverUrl,
    unlocked,
    total,
    completionPct,
    playtimeMinutes,
    lastPlayedAt,
  ];
}

/// One achievement inside a game.
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.name,
    required this.unlocked,
    this.description,
    this.iconUrl,
    this.unlockedAt,
    this.rarityPct,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: _nonEmpty(json['description']),
      iconUrl: _nonEmpty(json['icon_url']),
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: _date(json['unlocked_at']),
      rarityPct: (json['rarity_pct'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool unlocked;
  final DateTime? unlockedAt;

  /// Share of players with it unlocked, 0-100.
  final double? rarityPct;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconUrl,
    unlocked,
    unlockedAt,
    rarityPct,
  ];
}

/// A game's progress plus its achievement list.
class GameAchievements extends Equatable {
  const GameAchievements({required this.game, required this.achievements});

  factory GameAchievements.fromJson(Map<String, dynamic> json) {
    final list = json['achievements'] as List<dynamic>? ?? const [];
    return GameAchievements(
      game: GameProgress.fromJson(json),
      achievements: [
        for (final a in list.cast<Map<String, dynamic>>())
          Achievement.fromJson(a),
      ],
    );
  }

  final GameProgress game;
  final List<Achievement> achievements;

  /// Unlocked first (newest first), then locked in API order.
  List<Achievement> get sorted {
    final unlocked = achievements.where((a) => a.unlocked).toList()
      ..sort((a, b) {
        final ad = a.unlockedAt, bd = b.unlockedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    return [...unlocked, ...achievements.where((a) => !a.unlocked)];
  }

  @override
  List<Object?> get props => [game, achievements];
}

/// Totals for one provider.
class ProviderAchievementTotals extends Equatable {
  const ProviderAchievementTotals({
    required this.provider,
    required this.unlocked,
    required this.total,
    required this.games,
  });

  factory ProviderAchievementTotals.fromJson(Map<String, dynamic> json) {
    return ProviderAchievementTotals(
      provider:
          GameProvider.fromApi(json['provider'] as String?) ??
          GameProvider.steam,
      unlocked: (json['unlocked'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      games: (json['games'] as num?)?.toInt() ?? 0,
    );
  }

  final GameProvider provider;
  final int unlocked;
  final int total;
  final int games;

  @override
  List<Object?> get props => [provider, unlocked, total, games];
}

/// A recently unlocked achievement.
class RecentAchievement extends Equatable {
  const RecentAchievement({
    required this.provider,
    required this.externalGameId,
    required this.gameName,
    required this.achievementName,
    required this.unlockedAt,
    this.description,
    this.iconUrl,
    this.rarityPct,
  });

  factory RecentAchievement.fromJson(Map<String, dynamic> json) {
    return RecentAchievement(
      provider:
          GameProvider.fromApi(json['provider'] as String?) ??
          GameProvider.steam,
      externalGameId: json['external_game_id'] as String? ?? '',
      gameName: json['game_name'] as String? ?? '',
      achievementName: json['achievement_name'] as String? ?? '',
      description: _nonEmpty(json['description']),
      iconUrl: _nonEmpty(json['icon_url']),
      unlockedAt:
          _date(json['unlocked_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      rarityPct: (json['rarity_pct'] as num?)?.toDouble(),
    );
  }

  final GameProvider provider;
  final String externalGameId;
  final String gameName;
  final String achievementName;
  final String? description;
  final String? iconUrl;
  final DateTime unlockedAt;
  final double? rarityPct;

  @override
  List<Object?> get props => [
    provider,
    externalGameId,
    gameName,
    achievementName,
    description,
    iconUrl,
    unlockedAt,
    rarityPct,
  ];
}

/// Response of `GET /users/me/achievements/summary`.
class AchievementSummary extends Equatable {
  const AchievementSummary({
    required this.totalUnlocked,
    required this.totalAvailable,
    required this.completionPct,
    required this.byProvider,
    required this.recent,
    required this.games,
  });

  factory AchievementSummary.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) =>
        (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    return AchievementSummary(
      totalUnlocked: (json['total_unlocked'] as num?)?.toInt() ?? 0,
      totalAvailable: (json['total_available'] as num?)?.toInt() ?? 0,
      completionPct: (json['completion_pct'] as num?)?.toDouble() ?? 0,
      byProvider: [
        for (final p in list('by_provider'))
          ProviderAchievementTotals.fromJson(p),
      ],
      recent: [for (final r in list('recent')) RecentAchievement.fromJson(r)],
      games: [for (final g in list('games')) GameProgress.fromJson(g)],
    );
  }

  final int totalUnlocked;
  final int totalAvailable;

  /// 0-100.
  final double completionPct;
  final List<ProviderAchievementTotals> byProvider;
  final List<RecentAchievement> recent;
  final List<GameProgress> games;

  bool get isEmpty => games.isEmpty && totalAvailable == 0;

  @override
  List<Object?> get props => [
    totalUnlocked,
    totalAvailable,
    completionPct,
    byProvider,
    recent,
    games,
  ];
}
