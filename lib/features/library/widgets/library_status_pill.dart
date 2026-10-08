import 'package:flutter/material.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Tone and icon for each library status.
extension GameStatusVisuals on GameStatus {
  PfTone get tone => switch (this) {
    GameStatus.planned => PfTone.neutral,
    GameStatus.playing => PfTone.connected,
    GameStatus.finished => PfTone.info,
    GameStatus.onHold => PfTone.warning,
    GameStatus.dropped => PfTone.error,
  };

  IconData get icon => switch (this) {
    GameStatus.planned => Icons.bookmark_border,
    GameStatus.playing => Icons.play_arrow_rounded,
    GameStatus.finished => Icons.check_rounded,
    GameStatus.onHold => Icons.pause_rounded,
    GameStatus.dropped => Icons.close_rounded,
  };
}

/// [StatusPill] for a library [GameStatus].
class LibraryStatusPill extends StatelessWidget {
  const LibraryStatusPill({
    required this.status,
    this.dense = false,
    super.key,
  });

  final GameStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: status.localizedName(context),
      tone: status.tone,
      icon: status.icon,
      dense: dense,
    );
  }
}
