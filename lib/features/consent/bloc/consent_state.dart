import 'package:equatable/equatable.dart';
import 'package:picklog/core/services/consent/consent_category.dart';

/// Snapshot of the user's consent choices, surfaced to the UI.
///
/// Mirrors [ConsentService]: [hasAnswered] drives the first-run prompt and the
/// per-[ConsentCategory] flags in [granted] drive the settings switches.
class ConsentState extends Equatable {
  const ConsentState({
    required this.hasAnswered,
    required this.granted,
    this.isSaving = false,
  });

  /// Whether the user has made an explicit consent choice (prompt dismissed).
  final bool hasAnswered;

  /// Current grant flag per category. Missing keys are treated as denied.
  final Map<ConsentCategory, bool> granted;

  /// Whether a consent choice is currently being persisted. Drives disabling
  /// the banner actions so a fast second tap can't race the first write.
  final bool isSaving;

  /// Whether [category] is currently granted. Denied by default.
  bool isGranted(ConsentCategory category) => granted[category] ?? false;

  @override
  List<Object?> get props => [
    hasAnswered,
    isSaving,
    for (final category in ConsentCategory.values) granted[category] ?? false,
  ];
}
