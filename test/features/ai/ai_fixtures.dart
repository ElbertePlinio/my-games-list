import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/library/library_repository.dart';

class MockAiRepository extends Mock implements AiRepository {}

class MockLibraryRepository extends Mock implements LibraryRepository {}

const kStatusConsented = AiStatus(
  enabled: true,
  consented: true,
  dailyLimit: 20,
  usedToday: 3,
  model: 'gpt-6-luna',
);

const kStatusNoConsent = AiStatus(
  enabled: true,
  consented: false,
  dailyLimit: 20,
  usedToday: 0,
);

const kStatusDisabled = AiStatus(
  enabled: false,
  consented: false,
  dailyLimit: 20,
  usedToday: 0,
);

const kPickHades = PlayNextPick(
  libraryEntryId: 'entry-1',
  game: AiGameRef(igdbId: 1, name: 'Hades', coverUrl: null),
  reason: 'Short runs fit a quick evening and you loved roguelikes.',
  estimatedSessionMinutes: 45,
);

const kPickOuterWilds = PlayNextPick(
  libraryEntryId: 'entry-2',
  game: AiGameRef(igdbId: 2, name: 'Outer Wilds'),
  reason: 'A story you can explore at your own pace.',
  estimatedSessionMinutes: 90,
);

const kPlayNextResult = PlayNextResult(
  picks: [kPickHades, kPickOuterWilds],
  remainingToday: 16,
);

final kDiscoverPick = DiscoverPick(
  game: AiDiscoverGame(
    id: 10,
    name: 'Stardew Valley',
    totalRating: 88.4,
    firstReleaseDate: DateTime.utc(2016, 2, 26),
  ),
  reason: 'A calm farming loop for slow weekends.',
);
