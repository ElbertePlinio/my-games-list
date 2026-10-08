import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/integrations/integrations_l10n.dart';
import 'package:picklog/features/integrations/integrations_models.dart';

/// Rarity at or below this share of players counts as rare.
const double kRareAchievementPct = 10;

/// Ember ring that sweeps from 0 to [percent] on first build.
///
/// The ring is the hub's single ember accent. Under reduced motion it shows
/// the final value at once.
class CompletionRing extends StatelessWidget {
  const CompletionRing({
    required this.percent,
    this.size = 128,
    this.semanticLabel,
    super.key,
  });

  /// 0-100.
  final double percent;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final target = (percent / 100).clamp(0.0, 1.0);
    final stroke = math.max(6.0, size / 14);
    return Semantics(
      label: semanticLabel ?? '${percent.round()}%',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: PfMotion.of(context, PfMotion.reveal * 2),
        curve: PfMotion.forge,
        builder: (context, value, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              track: colors.surface3,
              fill: colors.ember,
              stroke: stroke,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(stroke * 1.5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${(value * 100).round()}%',
                    style: PfTypography.monoStyle(
                      colors.textHi,
                      size: size * 0.22,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.stroke != stroke;
}

/// Thin neutral progress bar. Full completion turns the connected tone.
class AchievementProgressBar extends StatelessWidget {
  const AchievementProgressBar({required this.fraction, super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final value = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: PfRadius.pillAll,
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
        color: value >= 1 ? colors.connected : colors.textMed,
        backgroundColor: colors.surface3,
      ),
    );
  }
}

/// Square achievement icon with a trophy fallback. Locked icons are dimmed.
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    required this.url,
    this.locked = false,
    this.size = 44,
    super.key,
  });

  final String? url;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(color: colors.surface2),
      child: Center(
        child: Icon(
          locked ? Icons.lock_outline : Icons.emoji_events_outlined,
          size: size * 0.5,
          color: colors.textLow,
        ),
      ),
    );
    Widget image = url == null
        ? fallback
        : PfNetworkImage(url: url!, placeholder: fallback, error: fallback);
    if (locked && url != null) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: PfRadius.smAll,
          border: Border.all(color: colors.hairline),
        ),
        child: image,
      ),
    );
  }
}

/// Rarity pill: "Rare" under the threshold, otherwise the share of players.
class RarityPill extends StatelessWidget {
  const RarityPill({required this.rarityPct, super.key});

  final double rarityPct;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rare = rarityPct <= kRareAchievementPct;
    return StatusPill(
      label: rare
          ? '${l10n.achievementsRare} · ${formatRarity(rarityPct)}%'
          : l10n.achievementsRarity(formatRarity(rarityPct)),
      tone: rare ? PfTone.warning : PfTone.neutral,
      icon: rare ? Icons.diamond_outlined : null,
      dense: true,
    );
  }
}

/// One achievement row: icon, name, description, date and rarity.
class AchievementTile extends StatelessWidget {
  const AchievementTile({
    required this.name,
    required this.unlocked,
    this.description,
    this.iconUrl,
    this.unlockedAt,
    this.rarityPct,
    this.subtitle,
    super.key,
  });

  factory AchievementTile.fromAchievement(Achievement a, {Key? key}) =>
      AchievementTile(
        key: key,
        name: a.name,
        unlocked: a.unlocked,
        description: a.description,
        iconUrl: a.iconUrl,
        unlockedAt: a.unlockedAt,
        rarityPct: a.rarityPct,
      );

  final String name;
  final bool unlocked;
  final String? description;
  final String? iconUrl;
  final DateTime? unlockedAt;
  final double? rarityPct;

  /// Optional line above the description, for example the game name.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final date = unlockedAt;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AchievementIcon(url: iconUrl, locked: !unlocked),
        const SizedBox(width: PfSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: colors.textHi,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: PfSpace.xs + 2),
              Wrap(
                spacing: PfSpace.sm,
                runSpacing: PfSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (unlocked && date != null)
                    Text(
                      l10n.achievementsUnlockedOn(
                        formatShortDate(context, date),
                      ),
                      style: PfTypography.monoStyle(colors.textMed, size: 11),
                    )
                  else if (!unlocked)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: colors.textLow,
                        ),
                        const SizedBox(width: PfSpace.xs),
                        Text(
                          l10n.achievementsLocked,
                          style: PfTypography.monoStyle(
                            colors.textMed,
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  if (rarityPct != null) RarityPill(rarityPct: rarityPct!),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PfSpace.sm),
        // Locked achievements are dimmed but keep readable text.
        child: unlocked ? content : Opacity(opacity: 0.62, child: content),
      ),
    );
  }
}

/// A game's progress row: cover, name, provider, progress bar and counts.
class GameProgressTile extends StatelessWidget {
  const GameProgressTile({required this.game, required this.onTap, super.key});

  final GameProgress game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final lastPlayed = game.lastPlayedAt;
    return GameTile(
      title: game.name,
      coverUrl: game.coverUrl,
      coverWidth: 48,
      onTap: onTap,
      meta: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(game.provider.icon, size: 13, color: colors.textMed),
            const SizedBox(width: PfSpace.xs),
            Text(
              game.provider.displayName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (lastPlayed != null)
          Text(
            l10n.achievementsLastPlayed(formatShortDate(context, lastPlayed)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(child: AchievementProgressBar(fraction: game.fraction)),
              const SizedBox(width: PfSpace.sm),
              Text(
                '${game.unlocked}/${game.total}',
                style: PfTypography.monoStyle(colors.textMed, size: 11),
              ),
            ],
          ),
        ),
      ],
      trailing: Icon(Icons.chevron_right, color: colors.textLow),
    );
  }
}
