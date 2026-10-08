import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

class MockIntegrationsRepository extends Mock
    implements IntegrationsRepository {}

final kLinkedAt = DateTime.utc(2026, 10, 1, 12);

LinkedAccount account({
  SyncStatus status = SyncStatus.ok,
  String name = 'Hornet',
  DateTime? lastSyncedAt,
}) => LinkedAccount(
  externalId: '76561198000000000',
  displayName: name,
  linkedAt: kLinkedAt,
  lastSyncedAt: lastSyncedAt,
  syncStatus: status,
);

List<LinkedProvider> providers({
  LinkedAccount? steam,
  LinkedAccount? xbox,
  bool psnAvailable = false,
}) => [
  LinkedProvider(
    provider: GameProvider.steam,
    available: true,
    experimental: false,
    account: steam,
  ),
  LinkedProvider(
    provider: GameProvider.xbox,
    available: true,
    experimental: false,
    account: xbox,
  ),
  const LinkedProvider(
    provider: GameProvider.retroAchievements,
    available: false,
    experimental: false,
  ),
  LinkedProvider(
    provider: GameProvider.psn,
    available: psnAvailable,
    experimental: true,
  ),
];

final kGameHades = GameProgress(
  provider: GameProvider.steam,
  externalGameId: '1145360',
  name: 'Hades',
  igdbId: 113112,
  unlocked: 30,
  total: 49,
  completionPct: 61.2,
  lastPlayedAt: DateTime.utc(2026, 10, 5, 12),
);

final kGameHalo = GameProgress(
  provider: GameProvider.xbox,
  externalGameId: 'halo',
  name: 'Halo Infinite',
  unlocked: 10,
  total: 100,
  completionPct: 10,
  lastPlayedAt: DateTime.utc(2026, 9, 1, 12),
);

const kGameOld = GameProgress(
  provider: GameProvider.steam,
  externalGameId: '400',
  name: 'Portal',
  unlocked: 15,
  total: 15,
  completionPct: 100,
);

final kSummary = AchievementSummary(
  totalUnlocked: 55,
  totalAvailable: 164,
  completionPct: 33.5,
  byProvider: const [
    ProviderAchievementTotals(
      provider: GameProvider.steam,
      unlocked: 45,
      total: 64,
      games: 2,
    ),
    ProviderAchievementTotals(
      provider: GameProvider.xbox,
      unlocked: 10,
      total: 100,
      games: 1,
    ),
  ],
  recent: [
    RecentAchievement(
      provider: GameProvider.steam,
      externalGameId: '1145360',
      gameName: 'Hades',
      achievementName: 'Escaped Tartarus',
      description: 'Clear the first region.',
      unlockedAt: DateTime.utc(2026, 10, 5, 12),
      rarityPct: 4.2,
    ),
  ],
  games: [kGameOld, kGameHalo, kGameHades],
);

final kHadesAchievements = GameAchievements(
  game: kGameHades,
  achievements: [
    const Achievement(id: 'a1', name: 'Locked One', unlocked: false),
    Achievement(
      id: 'a2',
      name: 'Escaped Tartarus',
      unlocked: true,
      unlockedAt: DateTime.utc(2026, 10, 5, 12),
      rarityPct: 4.2,
    ),
    Achievement(
      id: 'a3',
      name: 'First Steps',
      unlocked: true,
      unlockedAt: DateTime.utc(2026, 9, 1, 12),
      rarityPct: 80,
    ),
  ],
);
