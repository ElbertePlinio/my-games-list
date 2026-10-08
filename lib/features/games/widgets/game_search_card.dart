import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';

/// Hero prefix for search result covers.
const String kSearchHeroPrefix = 'search-';

/// Search result row: cover, name, genres, platforms and release date.
class GameSearchCard extends StatelessWidget {
  const GameSearchCard({super.key, required this.game});

  final SearchGame game;

  String _semanticsLabel() {
    final parts = <String>[game.name];
    if (game.genres.isNotEmpty) {
      parts.add(game.genres.map((g) => g.name).take(2).join(', '));
    }
    if (game.platforms.isNotEmpty) {
      parts.add(game.platforms.map((p) => p.name).take(2).join(', '));
    }
    if (game.firstReleaseDate != null) {
      parts.add(game.firstReleaseDate!.year.toString());
    }
    return parts.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return GameTile(
      title: game.name,
      coverUrl: game.coverUrl,
      coverWidth: 64,
      heroTag: gameCoverHeroTag(kSearchHeroPrefix, game.id),
      semanticLabel: _semanticsLabel(),
      onTap: () =>
          openGameDetails(context, game.id, heroPrefix: kSearchHeroPrefix),
      meta: [
        if (game.genres.isNotEmpty)
          _InfoRow(
            icon: Icons.category_outlined,
            text: game.genres.map((g) => g.name).take(2).join(', '),
          ),
        if (game.platforms.isNotEmpty)
          _InfoRow(
            icon: Icons.devices_outlined,
            text: game.platforms.map((p) => p.name).take(2).join(', '),
          ),
        if (game.firstReleaseDate != null)
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: DateFormat.yMMMd(locale).format(game.firstReleaseDate!),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textLow),
          const SizedBox(width: PfSpace.xs + 2),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
