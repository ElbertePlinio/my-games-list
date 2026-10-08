import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/favorite_button.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_formatters.dart';
import 'package:picklog/features/library/widgets/library_entry_actions.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Library list row: swipe right to toggle the favorite, swipe left to change
/// the status. Both offer an undo. The menu repeats the actions for pointer
/// and screen reader users.
class LibraryEntryRow extends StatelessWidget {
  const LibraryEntryRow({
    required this.entry,
    required this.heroPrefix,
    this.swipeable = true,
    super.key,
  });

  final LibraryEntry entry;
  final String heroPrefix;
  final bool swipeable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final meta = <Widget>[
      LibraryStatusPill(status: entry.status, dense: true),
      if (entry.score != null) ScoreBadge(score: entry.score),
      Text(
        [
          if (entry.platform != null) entry.platform!.displayName,
          formatPlaytime(context, entry.playtimeMinutes),
        ].join(' · '),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    final tile = GameTile(
      title: entry.game.name,
      coverUrl: entry.game.coverUrl,
      heroTag: gameCoverHeroTag(heroPrefix, entry.game.igdbId),
      semanticLabel: l10n.libraryEntryLabel(
        entry.game.name,
        entry.status.localizedName(context),
      ),
      meta: meta,
      onTap: () =>
          openGameDetails(context, entry.game.igdbId, heroPrefix: heroPrefix),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FavoriteButton(
            isFavorite: entry.isFavorite,
            addLabel: l10n.addToFavorites,
            removeLabel: l10n.favorited,
            onPressed: () => LibraryEntryActions.toggleFavorite(context, entry),
          ),
          LibraryEntryMenuButton(entry: entry),
        ],
      ),
    );

    if (!swipeable) return tile;

    return Dismissible(
      key: ValueKey('library-swipe-${entry.id}'),
      // The row stays; a swipe only triggers the action.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          LibraryEntryActions.toggleFavorite(context, entry);
        } else {
          await LibraryEntryActions.changeStatus(context, entry);
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        icon: entry.isFavorite ? Icons.heart_broken_outlined : Icons.favorite,
        label: entry.isFavorite ? l10n.favorited : l10n.addToFavorites,
        tone: PfTone.ember,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        icon: Icons.swap_horiz,
        label: l10n.libraryChangeStatus,
        tone: PfTone.info,
      ),
      child: tile,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.tone,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final PfTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final foreground = colors.toneForeground(tone);
    final start = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: PfSpace.xl),
      decoration: BoxDecoration(
        color: colors.toneBackground(tone),
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.toneFill(tone).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!start) ...[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: foreground),
            ),
            const SizedBox(width: PfSpace.sm),
          ],
          Icon(icon, color: foreground),
          if (start) ...[
            const SizedBox(width: PfSpace.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}

/// Library grid card: cover with the user's score, status below, and a menu
/// on the cover. Long press opens the status picker.
class LibraryEntryGridCard extends StatelessWidget {
  const LibraryEntryGridCard({
    required this.entry,
    required this.heroPrefix,
    super.key,
  });

  final LibraryEntry entry;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onLongPress: () => LibraryEntryActions.changeStatus(context, entry),
            child: GameCard(
              title: entry.game.name,
              coverUrl: entry.game.coverUrl,
              score: entry.score,
              heroTag: gameCoverHeroTag(heroPrefix, entry.game.igdbId),
              subtitle: entry.status.localizedName(context),
              semanticLabel: l10n.libraryEntryLabel(
                entry.game.name,
                entry.status.localizedName(context),
              ),
              overlay: entry.isFavorite
                  ? Container(
                      padding: const EdgeInsets.all(PfSpace.xs),
                      decoration: BoxDecoration(
                        color: PicklogColors.imageScrim.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 14,
                        color: context.pfColors.ember,
                        semanticLabel: l10n.favorited,
                      ),
                    )
                  : null,
              onTap: () => openGameDetails(
                context,
                entry.game.igdbId,
                heroPrefix: heroPrefix,
              ),
            ),
          ),
        ),
        Positioned(
          right: PfSpace.xs,
          bottom:
              GameCard.captionHeightFor(MediaQuery.textScalerOf(context)) +
              PfSpace.xs,
          child: Material(
            color: PicklogColors.imageScrim.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: SizedBox.square(
              dimension: 36,
              child: LibraryEntryMenuButton(
                entry: entry,
                includeFavorite: true,
                color: PicklogColors.onImage,
                iconSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
