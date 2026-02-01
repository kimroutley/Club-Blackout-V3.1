import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Guardrail: UI must not directly mutate engine-owned fields.
///
/// This test intentionally scans UI sources for obvious state-mutation patterns
/// that should be routed through `GameEngine` helpers (or `handleScriptAction`).
void main() {
  test('UI does not directly mutate engine state', () {
    final uiRoot = Directory(p.join('lib', 'ui'));
    if (!uiRoot.existsSync()) {
      fail('Expected UI directory not found: ${uiRoot.path}');
    }

    // Some UI entrypoints live at lib/ root.
    final extraUiFiles = <File>[
      File(p.join('lib', 'main.dart')),
      File(p.join('lib', 'scoreboard_preview.dart')),
    ].where((f) => f.existsSync()).toList();

    // High-signal patterns that should never appear in UI.
    //
    // Notes on false-positives:
    // - We deliberately scope Player-mutation checks to common variable names
    //   (player/target/victim/etc.) and engine.players[index] forms.
    // - This avoids flagging unrelated widget fields like `this.isAlive`.
    final bannedPatterns = <RegExp, String>{
      // Engine nightActions map mutations
      RegExp(r'\.nightActions\s*\[[^\]]+\]\s*=(?!=)'):
          'Direct nightActions assignment',
      RegExp(r'\.nightActions\s*\.\s*remove\s*\('):
          'Direct nightActions.remove(...)',
      RegExp(r'\.nightActions\s*\.\s*clear\s*\('):
          'Direct nightActions.clear()',

      // Engine deadPlayerIds mutations
      RegExp(r'\.deadPlayerIds\s*=(?!=)'): 'Direct deadPlayerIds assignment',
      RegExp(r'\.deadPlayerIds\s*\.\s*add(All)?\s*\('):
          'Direct deadPlayerIds.add/addAll(...)',
      RegExp(r'\.deadPlayerIds\s*\.\s*remove(Where)?\s*\('):
          'Direct deadPlayerIds.remove/removeWhere(...)',
      RegExp(r'\.deadPlayerIds\s*\.\s*clear\s*\('):
          'Direct deadPlayerIds.clear()',

      // Engine phase mutation (use engine helpers)
      RegExp(r'\.currentPhase\s*=(?!=)'): 'Direct currentPhase assignment',

      // Common UI-side Player mutations (should be routed through GameEngine)
      RegExp(
        r'\b(player|target|victim|prey|clinger|obsession|messyBitch|secondWind|silverFox|lightweight|medic|sober|roofi|bouncer)\s*\.\s*(isAlive|isEnabled|role|statusEffects)\s*=(?!=)',
      ): 'Direct Player field assignment',
      RegExp(
        r'\b(player|target|victim|prey|clinger|obsession|messyBitch|secondWind|silverFox|lightweight|medic|sober|roofi|bouncer)\s*\.\s*statusEffects\s*\.\s*(add|addAll|remove|removeWhere|clear)\s*\(',
      ): 'Direct statusEffects mutation',
      RegExp(
        r'\b(player|target|victim|prey|clinger|obsession|messyBitch|secondWind|silverFox|lightweight|medic|sober|roofi|bouncer)\s*\.\s*(applyStatus|removeStatus)\s*\(',
      ): 'Direct Player status mutation',
      RegExp(
        r'\b(gameEngine|engine|widget\.gameEngine)\s*\.\s*players\s*\[[^\]]+\]\s*\.\s*(isAlive|isEnabled|role|statusEffects)\s*=(?!=)',
      ): 'Direct engine.players[index] field assignment',
      RegExp(
        r'\b(gameEngine|engine|widget\.gameEngine)\s*\.\s*players\s*\[[^\]]+\]\s*\.\s*statusEffects\s*\.\s*(add|addAll|remove|removeWhere|clear)\s*\(',
      ): 'Direct engine.players[index].statusEffects mutation',

      // Strict catch-all: any assignment/mutation of these fields in UI.
      // Excludes `this.<field> = ...` so widget constructor default params
      // like `this.isAlive = true` are not flagged.
      RegExp(
        r'\b(?!this\b)[A-Za-z_][A-Za-z0-9_]*\s*\.\s*(isAlive|isEnabled|role|statusEffects)\s*=(?!=)',
      ): 'Strict: assignment to isAlive/isEnabled/role/statusEffects',
      RegExp(
        r'\b(?!this\b)[A-Za-z_][A-Za-z0-9_]*\s*\.\s*statusEffects\s*\.\s*(add|addAll|remove|removeWhere|clear)\s*\(',
      ): 'Strict: statusEffects mutation',
      RegExp(
        r'\b(?!this\b)[A-Za-z_][A-Za-z0-9_]*\s*\.\s*(applyStatus|removeStatus)\s*\(',
      ): 'Strict: applyStatus/removeStatus called in UI',
    };

    final violations = <String>[];

    final dartFiles = <File>[
      ...uiRoot
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.dart')),
      ...extraUiFiles,
    ]
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in dartFiles) {
      final contents = file.readAsStringSync();

      for (final entry in bannedPatterns.entries) {
        final pattern = entry.key;
        final description = entry.value;

        final matches = pattern.allMatches(contents).toList();
        if (matches.isEmpty) continue;

        for (final match in matches) {
          final lineInfo = _lineAt(contents, match.start);
          final rel = p.relative(file.path);
          violations.add('$rel:${lineInfo.lineNumber}: $description\n'
              '  ${lineInfo.lineText.trim()}');
        }
      }
    }

    if (violations.isNotEmpty) {
      final joined = violations.join('\n');
      fail('UI must not mutate engine state directly. Found violations:\n\n$joined');
    }
  });
}

class _LineInfo {
  _LineInfo(this.lineNumber, this.lineText);

  final int lineNumber;
  final String lineText;
}

_LineInfo _lineAt(String contents, int offset) {
  // Compute 1-based line number and extract that line.
  var lineNumber = 1;
  var lineStart = 0;

  for (var i = 0; i < offset && i < contents.length; i++) {
    if (contents.codeUnitAt(i) == 0x0A /* \n */) {
      lineNumber++;
      lineStart = i + 1;
    }
  }

  var lineEnd = contents.indexOf('\n', lineStart);
  if (lineEnd == -1) lineEnd = contents.length;

  final lineText = contents.substring(lineStart, lineEnd);
  return _LineInfo(lineNumber, lineText);
}
