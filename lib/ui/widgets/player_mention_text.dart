import 'package:flutter/material.dart';

import '../../models/player.dart';
import 'unified_player_tile.dart';

class PlayerMentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Player> players;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const PlayerMentionText({
    super.key,
    required this.text,
    required this.players,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  static String _escapeRegex(String value) {
    return value.replaceAllMapped(
      RegExp(r'[\\^$.*+?()\[\]{}|]'),
      (m) => '\\${m[0]}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = text;
    final activePlayers =
        players.where((p) => p.name.trim().isNotEmpty).toList(growable: false);

    if (raw.trim().isEmpty || activePlayers.isEmpty) {
      return Text(
        raw,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final byLowerName = <String, Player>{
      for (final p in activePlayers) p.name.trim().toLowerCase(): p,
    };

    // Prefer longer names first to avoid partial matches (e.g., "Ann" inside "Anna").
    final names = byLowerName.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final alternation = names.map(_escapeRegex).join('|');
    if (alternation.isEmpty) {
      return Text(
        raw,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Match whole names with conservative boundaries (avoid matching inside words).
    final pattern = RegExp(
      '(^|[^A-Za-z0-9_])($alternation)(?![A-Za-z0-9_])',
      caseSensitive: false,
    );

    final spans = <InlineSpan>[];
    var index = 0;

    for (final match in pattern.allMatches(raw)) {
      final start = match.start;
      final end = match.end;
      final prefix = match.group(1) ?? '';
      final nameMatch = match.group(2) ?? '';

      final prefixStart = start;
      final prefixEnd = start + prefix.length;

      // Add text before the match.
      if (index < prefixStart) {
        spans.add(
            TextSpan(text: raw.substring(index, prefixStart), style: style));
      }

      // Add the boundary prefix char(s) (space/punct) if present.
      if (prefix.isNotEmpty) {
        spans.add(TextSpan(
            text: raw.substring(prefixStart, prefixEnd), style: style));
      }

      final player = byLowerName[nameMatch.toLowerCase()];
      if (player == null) {
        spans.add(TextSpan(text: nameMatch, style: style));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: UnifiedPlayerTile.minimal(player: player),
            ),
          ),
        );
      }

      index = end;
    }

    if (index < raw.length) {
      spans.add(TextSpan(text: raw.substring(index), style: style));
    }

    // If we didn't match anything, fall back to Text to avoid layout surprises.
    final didReplace = spans.any((s) => s is WidgetSpan);
    if (!didReplace) {
      return Text(
        raw,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
