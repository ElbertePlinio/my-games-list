import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/features/games/search_game_model.dart';

class GameSearchCard extends StatelessWidget {
  const GameSearchCard({super.key, required this.game});

  final SearchGame game;

  void _openDetails(BuildContext context) {
    context.pushNamed(
      'gameDetails',
      pathParameters: {'id': game.id.toString()},
    );
  }

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Semantics(
        label: _semanticsLabel(),
        button: true,
        excludeSemantics: true,
        onTap: () => _openDetails(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GameCover(coverUrl: game.coverUrl, gameId: game.id),
                const SizedBox(width: 16),
                Expanded(child: _GameInfo(game: game)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCover extends StatelessWidget {
  const _GameCover({this.coverUrl, required this.gameId});

  final String? coverUrl;
  final int gameId;

  @override
  Widget build(BuildContext context) {
    // Use high-res cover URL
    final highResCoverUrl = coverUrl != null
        ? getHighResUrl(coverUrl!, ImageSize.coverBig)
        : null;

    return VisibilityHero(
      tag: 'game-cover-$gameId',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 90,
          height: 120,
          child: highResCoverUrl != null
              ? CachedNetworkImage(
                  imageUrl: highResCoverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _PlaceholderCover(),
                )
              : _PlaceholderCover(),
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.videogame_asset, size: 48, color: Colors.white54),
    );
  }
}

class _GameInfo extends StatelessWidget {
  const _GameInfo({required this.game});

  final SearchGame game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (game.genres.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.category,
            text: game.genres.map((g) => g.name).take(2).join(', '),
          ),
          const SizedBox(height: 4),
        ],
        if (game.platforms.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.devices,
            text: game.platforms.map((p) => p.name).take(2).join(', '),
          ),
          const SizedBox(height: 4),
        ],
        if (game.firstReleaseDate != null) ...[
          _InfoRow(
            icon: Icons.calendar_today,
            text: DateFormat.yMMMd().format(game.firstReleaseDate!),
          ),
        ],
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
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
