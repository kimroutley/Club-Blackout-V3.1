// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, invalid_null_aware_operator, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../logic/ability_system.dart';
import '../../logic/game_engine.dart';
import '../../models/game_log_entry.dart';
import '../../models/player.dart';
import '../../models/script_step.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/sound_service.dart';
import '../../utils/game_exceptions.dart';
import '../styles.dart';
import '../utils/player_sort.dart';
import '../widgets/bulletin_dialog_shell.dart';
import '../widgets/club_alert_dialog.dart';
import '../widgets/day_scene_dialog.dart';
import '../widgets/game_drawer.dart';
import '../widgets/interactive_script_card.dart';
import '../widgets/night_phase_player_tile.dart';
import '../widgets/phase_card.dart';
import '../widgets/player_tile.dart';
import '../widgets/role_reveal_widget.dart';
import '../widgets/swap_setup_flow.dart';
import 'host_overview_screen.dart';

class GameScreen extends StatefulWidget {
  final GameEngine gameEngine;

  const GameScreen({super.key, required this.gameEngine});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _stepKeys = {};
  int _lastScriptIndex = 0;
  final Set<String> _currentSelection = {};
  final Map<String, int> _voteCounts = {};
  bool _rumourMillExpanded = false;
  bool _abilityFabExpanded = false;
  final Set<String> _shownAbilityNotifications =
      {}; // Track shown notifications
  final Map<String, bool> _abilityLastState =
      {}; // Track last seen activation state
  bool _abilityNotificationsPrimed =
      false; // Avoid firing snacks before first activation edge
  Timer? _scrollDebounceTimer;

  bool _autoOpenedDayDialog = false;

  @override
  void initState() {
    super.initState();
    _lastScriptIndex = widget.gameEngine.currentScriptIndex;

    // Update theme based on active roles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDynamicTheme();
    });

    // ignore: unused_element
    widget.gameEngine.onPhaseChanged = (oldPhase, newPhase) {
      if (mounted) {
        unawaited(SoundService().playPhaseTransition());
        setState(() {});
        _scrollToStep(widget.gameEngine.currentScriptIndex);

        // Update theme when phase changes (different roles may be active)
        _updateDynamicTheme();

        // UX: After the last night action, go straight into Day Phase dialog.
        if (newPhase == GamePhase.day && !_autoOpenedDayDialog) {
          _autoOpenedDayDialog = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showDaySceneDialog();
          });
        }

        // Reset guard when leaving day.
        if (newPhase != GamePhase.day) {
          _autoOpenedDayDialog = false;
        }
      }
    };

    widget.gameEngine.onClingerDoubleDeath = (clingerName, obsessionName) {
      if (mounted) {
        _showClingerDoubleDeathDialog(clingerName, obsessionName);
      }
    };

    widget.gameEngine.onClubManagerReveal = (target) {
      // Ensure specific target role reveal
      if (mounted) {
        showRoleReveal(
          context,
          target.role,
          target.name,
          subtitle: 'Club Manager Investigation',
        );
      }
    };
  }

  void _showDaySceneDialog() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DaySceneDialog(
        gameEngine: widget.gameEngine,
        selectedNavIndex: 0,
        onNavigate: (index) {
          navigator.pop(); // close dialog
          if (index == 0) {
            navigator.pop(); // return to previous screen (home)
          }
        },
        onGameLogTap: () {
          navigator.pop(); // close dialog
          _showLog();
        },
        onComplete: () {
          // Advance through all remaining day phase steps
          int safety = 0;
          do {
            widget.gameEngine.advanceScript();
            safety++;
          } while (safety < 10 &&
              widget.gameEngine.currentPhase == GamePhase.day &&
              widget.gameEngine.currentScriptStep != null &&
              widget.gameEngine.currentScriptStep!.isNight == false);
          _scrollToBottom();
        },
        onGameEnd: (winner, message) {
          navigator.pop(); // Close dialog
          _showGameEndDialog(winner, message);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Update theme based on active player roles
  void _updateDynamicTheme() {
    if (!mounted) return;

    try {
      final themeService =
          Provider.of<DynamicThemeService>(context, listen: false);
      final activeRoles = widget.gameEngine.guests.map((p) => p.role).toList();

      if (activeRoles.isNotEmpty) {
        // Hybrid theming: combine game background with role colors
        themeService.updateFromBackgroundAndRoles(
          'Backgrounds/Club Blackout V2 Game Background.png',
          activeRoles,
        );
      } else {
        // Fallback to background-only
        themeService.updateFromBackground(
          'Backgrounds/Club Blackout V2 Game Background.png',
        );
      }
    } catch (e) {
      debugPrint('Failed to update dynamic theme: $e');
    }
  }

  void _scrollToStep(int index, {double alignment = 0.0, bool gentle = false}) {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 70), () {
      if (!mounted) return;
      final key = _stepKeys[index];
      final ctx = key?.currentContext;
      if (ctx != null && _scrollController.hasClients) {
        final box = ctx.findRenderObject();
        final viewport = box != null ? RenderAbstractViewport.of(box) : null;
        if (box is RenderBox && viewport != null) {
          final offset = viewport.getOffsetToReveal(box, alignment).offset;

          // Adjustment: Ensure the active card sits below the top AppBar.
          final targetOffset = offset - 110.0;

          final current = _scrollController.offset;
          final distance = (targetOffset - current).abs();
          final clampedOffset = targetOffset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );
          final duration = Duration(milliseconds: gentle ? 200 : 280);
          if (distance < 200) {
            _scrollController.animateTo(
              clampedOffset,
              duration: duration,
              curve: Curves.easeOutCubic,
            );
          } else {
            _scrollController.animateTo(
              clampedOffset,
              duration: duration,
              curve: Curves.easeInOut,
            );
          }
          return;
        }
      }

      // Fallback if no context yet
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final fallbackKey = _stepKeys[index];
        final fallbackCtx = fallbackKey?.currentContext;
        if (fallbackCtx != null) {
          Scrollable.ensureVisible(
            fallbackCtx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            alignment: alignment,
          );
        } else if (index == widget.gameEngine.scriptQueue.length - 1) {
          _scrollToBottom(durationMs: gentle ? 220 : 320);
        }
      });
    });
  }

  void _prewarmNextStepScroll() {
    final nextIndex = widget.gameEngine.currentScriptIndex + 1;
    final steps = widget.gameEngine.scriptQueue;
    if (nextIndex >= steps.length) return;
    _stepKeys.putIfAbsent(nextIndex, () => GlobalKey());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToStep(nextIndex, alignment: 0.1, gentle: true);
    });
  }

  void _scrollToBottom({int durationMs = 500}) {
    if (_scrollController.hasClients) {
      // Add extra offset to really push it up if possible
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _checkScroll() {
    if (widget.gameEngine.currentScriptIndex != _lastScriptIndex) {
      final newIndex = widget.gameEngine.currentScriptIndex;
      _lastScriptIndex = newIndex;
      // Force scroll on both forward and backward navigation
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _scrollToStep(newIndex),
      );
    }
  }

  void _advanceScript() {
    try {
      final step = widget.gameEngine.currentScriptStep;
      if (step != null &&
          (step.actionType == ScriptActionType.selectPlayer ||
              step.actionType == ScriptActionType.selectTwoPlayers)) {
        if (step.id == 'day_vote' && _voteCounts.isNotEmpty) {
          final votedPlayers =
              _voteCounts.entries.where((e) => e.value >= 2).toList();
          if (votedPlayers.isNotEmpty) {
            votedPlayers.sort((a, b) => b.value.compareTo(a.value));
            final mostVoted = votedPlayers.first;
            final maxVotes = mostVoted.value;
            final topVoters =
                votedPlayers.where((e) => e.value == maxVotes).toList();

            if (topVoters.length > 1) {
              // Tie handled silently (logged via engine if needed)
              widget.gameEngine.logAction(
                'Voting',
                'Vote tie! No one is eliminated.',
              );

              _voteCounts.clear();
              widget.gameEngine.advanceScript();
              setState(() => _currentSelection.clear());
              _scrollToBottom();
              _prewarmNextStepScroll();
              return;
            }
            final playerId = mostVoted.key;
            final player = widget.gameEngine.players.firstWhere(
              (p) => p.id == playerId,
            );
            final wasDealer = widget.gameEngine.voteOutPlayer(playerId);
            _voteCounts.clear();
            final Player victim = player;

            // Check if victim survived (e.g. Second Wind)
            // If they are alive and have pending conversion, it's Second Wind.
            final bool survivedVote =
                victim.isAlive && victim.secondWindPendingConversion;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => ClubAlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: survivedVote
                        ? Colors.amber
                        : (wasDealer
                            ? ClubBlackoutTheme.neonGreen.withValues(alpha: 0.6)
                            : ClubBlackoutTheme.neonRed.withValues(alpha: 0.6)),
                    width: 2,
                  ),
                ),
                title: Row(
                  children: [
                    Icon(
                      survivedVote
                          ? Icons.auto_awesome
                          : (wasDealer ? Icons.check_circle : Icons.cancel),
                      color: survivedVote
                          ? Colors.amber
                          : (wasDealer
                              ? ClubBlackoutTheme.neonGreen
                              : ClubBlackoutTheme.neonRed),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'VOTE RESULT',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (survivedVote) ...[
                      const Text(
                        'SECOND WIND!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${victim?.name ?? 'The target'} refuses to die!",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The Dealers must decide their fate.',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ] else ...[
                      Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        wasDealer
                            ? 'The group has successfully eliminated a Dealer!'
                            : 'The Party Animals have lost an innocent member.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],

                    // ADDED: Reactive Role Notification (Only if they actually died)
                    if (!survivedVote &&
                        victim != null &&
                        (victim.role.id == 'tea_spiller' ||
                            victim.role.id == 'predator' ||
                            victim.role.id == 'drama_queen')) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.amber),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'REACTIVE ROLE',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "This player was a ${victim?.role.name ?? 'mystery role'}.\nOpen the Action Menu (FAB) immediately to trigger their retaliation ability!",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      try {
                        if (widget.gameEngine.checkWinConditions()) {
                          final winner = widget.gameEngine.winner;
                          final message = widget.gameEngine.winMessage;
                          _showGameEndDialog(winner!, message!);
                        } else {
                          widget.gameEngine.advanceScript();
                          setState(() => _currentSelection.clear());
                          _scrollToBottom();
                          _prewarmNextStepScroll();
                        }
                      } on GameException catch (e) {
                        _showError(e.message);
                      } catch (e) {
                        _showError(e.toString());
                      }
                    },
                    style: ClubBlackoutTheme.neonButtonStyle(
                      wasDealer
                          ? ClubBlackoutTheme.neonGreen
                          : ClubBlackoutTheme.neonRed,
                    ),
                    child: const Text('CONTINUE'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        _executeNightAction(step);
      }

      widget.gameEngine.advanceScript();
      setState(() {
        _currentSelection.clear();
      });
      _scrollToBottom();
      _prewarmNextStepScroll();
    } on GameException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => ClubAlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Error', style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _executeNightAction(ScriptStep step) {
    if (_currentSelection.isEmpty) return;

    // 1. Comprehensive Logging for "Game Log" & Host Transparency
    // This ensures every tap of the green tick is recorded.
    final selectedNames = _currentSelection
        .map(
          (id) => widget.gameEngine.players.firstWhere((p) => p.id == id).name,
        )
        .join(', ');

    widget.gameEngine.logAction(
      'Action Confirmed: ${step.title}',
      'Host selected: $selectedNames',
    );

    // 2. Apply action using canonical engine logic (prevents UI/engine drift)
    widget.gameEngine.handleScriptAction(step, _currentSelection.toList());

    // 3. Specific Role Logic & Host Status Documentation
    if (step.actionType == ScriptActionType.selectPlayer) {
      final targetId = _currentSelection.first;
      final target = widget.gameEngine.players.firstWhere(
        (p) => p.id == targetId,
      );

      if (step.roleId == 'bouncer') {
        // Add visual status for Host Overview
        widget.gameEngine.applyPlayerStatus(targetId, 'Checked by Bouncer');

        // If the target was sent home by Sober, the Bouncer gets no normal result.
        if (target.soberSentHome) {
          showDialog(
            context: context,
            builder: (context) => ClubAlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Sent Home Early',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                '${target.name} was sent home early and is immune to all night requests.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        // Dealer check dialog (kept as immediate UI feedback)
        final isDealerAlly = target.role.alliance == 'criminal' ||
            target.role.id == 'dealer' ||
            target.alliance == 'The Dealers' ||
            target.role.alliance == 'The Dealers';
        _showBouncerConfirmation(target, isDealerAlly);
      } else if (step.id == 'creep_act') {
        // Log explicitly for transparency
        widget.gameEngine.logAction(
          'Creep Act',
          'The Creep is mimicking ${target.name} (${target.role.name})',
        );
        widget.gameEngine.applyPlayerStatus(targetId, 'Mimicked by Creep');
      } else if (step.id == 'clinger_obsession') {
        widget.gameEngine.logAction(
          'Clinger Act',
          'The Clinger is obsessed with ${target.name}',
        );
        // Note: Clinger obsession is usually secret, but Host needs to know.
        widget.gameEngine.applyPlayerStatus(targetId, 'Clinger Obsession');
      } else if (step.id == 'sober_act') {
        // Host Overview Status
        widget.gameEngine.applyPlayerStatus(targetId, 'Sent Home');

        widget.gameEngine.logAction(
          'Sober Mechanic',
          '${target.name} was sent home and will removed from script tonight.',
        );
      } else if (step.roleId == 'club_manager') {
        widget.gameEngine.logAction(
          'Club Manager',
          'Club Manager viewed ${target.name}\'s role.',
        );
        // Show reveal immediately
        showRoleReveal(
          context,
          target.role,
          target.name,
          subtitle: 'Club Manager Investigation',
        );
      }
    }
  }

  void _onPlayerSelected(String id) {
    final step = widget.gameEngine.currentScriptStep;
    if (step == null) return;

    setState(() {
      if (step.actionType == ScriptActionType.selectTwoPlayers) {
        if (_currentSelection.contains(id)) {
          _currentSelection.remove(id);
        } else if (_currentSelection.length < 2) {
          _currentSelection.add(id);
        }
      } else {
        _currentSelection.clear();
        _currentSelection.add(id);
      }
    });
  }

  void _showBouncerConfirmation(Player target, bool isDealerAlly) {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final accent = isDealerAlly
            ? ClubBlackoutTheme.neonGreen
            : ClubBlackoutTheme.neonRed;
        final titleText = isDealerAlly ? 'DEALER CONFIRMED' : 'NOT A DEALER';

        return BulletinDialogShell(
          accent: accent,
          maxWidth: 420,
          title: Text(
            titleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hyperwave',
              fontSize: 32,
              color: accent,
              shadows: ClubBlackoutTheme.textGlow(accent),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDealerAlly
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: accent,
                size: 60,
                shadows: ClubBlackoutTheme.iconGlow(accent),
              ),
              const SizedBox(height: 12),
              Text(
                target.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isDealerAlly
                    ? 'Is a Dealer or an ally of the Dealers.'
                    : 'Is not a known associate of the Dealers.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
              ),
              if (target.role.id == 'minor') ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(ClubBlackoutTheme.radiusMd),
                    border: Border.all(
                      color: cs.error.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: cs.error,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MINOR ID CHECKED',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Immunity stripped! The Minor is now vulnerable to Dealer attacks.',
                                style: TextStyle(fontSize: 13, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showCreepConfirmation(Player target) {
    showRoleReveal(
      context,
      target.role,
      target.name,
      subtitle: 'Creep Target',
      onComplete: () {}, // Optional callback
    );
  }

  void _showClingerConfirmation(Player target) {
    showRoleReveal(
      context,
      target.role,
      target.name,
      subtitle: 'OBSESSION TARGET',
      body: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ClubBlackoutTheme.neonPink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ClubBlackoutTheme.neonPink.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Text(
          'They are now bound to this player. They must vote exactly as their object of obsession votes. If the obsession dies, the Clinger dies.',
          style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showGameEndDialog(String winner, String message) {
    widget.gameEngine.enterEndGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final accent = winner.toLowerCase() == 'criminals'
            ? ClubBlackoutTheme.neonRed
            : ClubBlackoutTheme.neonGreen;

        return BulletinDialogShell(
          accent: accent,
          maxWidth: 520,
          title: Text(
            '${winner.toUpperCase()} WIN!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hyperwave',
              fontSize: 42,
              color: accent,
              shadows: ClubBlackoutTheme.textGlow(accent),
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Leave game screen
              },
              style: ClubBlackoutTheme.neonButtonStyle(accent),
              child: const Text('RETURN TO LOBBY'),
            ),
          ],
        );
      },
    );
  }

  void _showClingerDoubleDeathDialog(String clingerName, String obsessionName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        const accent = Colors.orange;
        return BulletinDialogShell(
          accent: accent,
          maxWidth: 520,
          title: const Text(
            'DOUBLE DEATH!',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          content: Text(
            "$clingerName's obsession, $obsessionName, has died. As a Clinger, $clingerName dies with them!",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: ClubBlackoutTheme.neonButtonStyle(accent),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void _showTabooList() {
    try {
      final lightweight = widget.gameEngine.players.firstWhere(
        (p) => p.role.id == 'lightweight' && p.isActive,
      );

      showDialog(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;

          return BulletinDialogShell(
            accent: ClubBlackoutTheme.neonPurple,
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            title: Row(
              children: [
                const Icon(
                  Icons.block,
                  color: ClubBlackoutTheme.neonPurple,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TABOO LIST',
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      color: ClubBlackoutTheme.neonPurple,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lightweight.name,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (lightweight.tabooNames.isEmpty)
                  Text(
                    'No taboo names assigned yet.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  SizedBox(
                    height: 320,
                    child: ListView.separated(
                      itemCount: lightweight.tabooNames.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final name = lightweight.tabooNames[index];
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(
                              ClubBlackoutTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: ClubBlackoutTheme.neonPurple
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.cancel_rounded,
                              color: ClubBlackoutTheme.neonPurple,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  '⚠️ The Lightweight dies if they speak any of these names!',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: ClubBlackoutTheme.neonPurple,
                  foregroundColor: Colors.black,
                ),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing taboo list: $e');
    }
  }

  void _showMedicSelfReviveDialog() {
    try {
      if (widget.gameEngine.currentPhase != GamePhase.night) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medic self-revive can only be queued at night.'),
          ),
        );
        return;
      }

      final medic = widget.gameEngine.players.firstWhere(
        (p) =>
            p.role.id == 'medic' &&
            widget.gameEngine.deadPlayerIds.contains(p.id),
      );

      final medicChoseRevive =
          (medic.medicChoice ?? '').toUpperCase() == 'REVIVE';
      final eligible = medicChoseRevive &&
          !medic.reviveUsed &&
          medic.deathDay == widget.gameEngine.dayCount;

      if (!eligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medic self-revive is not available right now.'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return BulletinDialogShell(
            accent: ClubBlackoutTheme.neonGreen,
            maxWidth: 520,
            title: Row(
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  color: ClubBlackoutTheme.neonGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MEDIC SELF-REVIVE',
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      color: ClubBlackoutTheme.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Queue the Medic to revive themselves at dawn?\n\nThis only works if the Medic died today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  try {
                    widget.gameEngine.queueMedicSelfRevive();
                    setState(() {});
                  } on GameException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ClubBlackoutTheme.neonGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('QUEUE SELF-REVIVE'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing Medic self-revive: $e');
    }
  }

  // ignore: unused_element
  void _showSilverFoxAbility() {
    try {
      final silverFox = widget.gameEngine.players.firstWhere(
        (p) =>
            p.role.id == 'silver_fox' && p.isActive && !p.silverFoxAbilityUsed,
      );

      final validTargets = sortedPlayersByDisplayName(
        widget.gameEngine.players
            .where((p) => p.isActive && p.id != silverFox.id)
            .toList(),
      );

      showDialog(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return BulletinDialogShell(
            accent: ClubBlackoutTheme.neonBlue,
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            title: Row(
              children: [
                const Icon(
                  Icons.visibility_rounded,
                  color: ClubBlackoutTheme.neonBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SILVER FOX REVEAL',
                    style: ClubBlackoutTheme.headingStyle.copyWith(
                      color: ClubBlackoutTheme.neonBlue,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose one player to ply with alcohol. They must reveal their role card to the group immediately.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(ClubBlackoutTheme.radiusMd),
                    border: Border.all(
                      color: cs.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      'ONE TIME USE ONLY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: ListView(
                    children: validTargets
                        .map(
                          (player) => ListTile(
                            title: Text(player.name),
                            trailing: Icon(
                              Icons.visibility_rounded,
                              color: cs.primary,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _useSilverFoxAbility(silverFox, player);
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing Silver Fox ability: $e');
    }
  }

  void _useSilverFoxAbility(Player silverFox, Player target) {
    silverFox.silverFoxAbilityUsed = true;

    widget.gameEngine.abilityResolver.queueAbility(
      ActiveAbility(
        abilityId: 'silver_fox_reveal',
        sourcePlayerId: silverFox.id,
        targetPlayerIds: [target.id],
        trigger: AbilityTrigger.dayAction,
        effect: AbilityEffect.reveal,
        priority: 1,
      ),
    );

    widget.gameEngine.logAction(
      'Silver Fox Reveal',
      'Silver Fox forced ${target.name} to reveal their role: ${target.role.name}!',
    );

    _showRoleReveal(target, 'Silver Fox Revealed');

    setState(() {});
  }

  void _showSecondWindConversion() {
    try {
      final secondWind = widget.gameEngine.players.firstWhere(
        (p) =>
            p.role.id == 'second_wind' &&
            p.secondWindPendingConversion &&
            !p.secondWindConverted,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          const accent = Color(0xFFDE3163);

          return BulletinDialogShell(
            accent: accent,
            title: Text(
              'SECOND WIND CONVERSION',
              style: ClubBlackoutTheme.headingStyle.copyWith(color: accent),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.autorenew, size: 60, color: accent),
                const SizedBox(height: 12),
                Text(
                  '${secondWind.name} was killed by the Dealers!',
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Do the Dealers agree to convert The Second Wind and bring them back to life as a Dealer?',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _refuseSecondWindConversion(secondWind);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.errorContainer,
                  foregroundColor: cs.onErrorContainer,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                ),
                icon: const Icon(Icons.close),
                label: const Text('REFUSE'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _acceptSecondWindConversion(secondWind);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.18),
                  foregroundColor: accent,
                  side: const BorderSide(color: accent, width: 1.5),
                ),
                icon: const Icon(Icons.check),
                label: const Text('ACCEPT'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing Second Wind conversion: $e');
    }
  }

  void _acceptSecondWindConversion(Player secondWind) {
    try {
      widget.gameEngine.handleScriptAction(
        const ScriptStep(
          id: 'second_wind_conversion_choice',
          title: 'Second Wind (Host Only)',
          readAloudText: '',
          instructionText: '',
          actionType: ScriptActionType.binaryChoice,
          roleId: 'dealer',
          isNight: true,
          optionLabels: ['CONVERT', 'KILL'],
        ),
        const ['convert'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${secondWind.name} is now a Dealer! No one dies tonight.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error converting Second Wind: $e');
    }
    setState(() {});
  }

  void _refuseSecondWindConversion(Player secondWind) {
    try {
      widget.gameEngine.handleScriptAction(
        const ScriptStep(
          id: 'second_wind_conversion_choice',
          title: 'Second Wind (Host Only)',
          readAloudText: '',
          instructionText: '',
          actionType: ScriptActionType.binaryChoice,
          roleId: 'dealer',
          isNight: true,
          optionLabels: ['CONVERT', 'KILL'],
        ),
        const ['kill'],
      );
    } catch (e) {
      debugPrint('Error refusing Second Wind conversion: $e');
    }

    setState(() {});
  }

  void _showAttackDogConversion() {
    try {
      final clinger = widget.gameEngine.players.firstWhere(
        (p) =>
            p.role.id == 'clinger' &&
            p.isActive &&
            p.clingerPartnerId != null &&
            !p.clingerAttackDogUsed,
      );

      final obsession = widget.gameEngine.players.firstWhere(
        (p) => p.id == clinger.clingerPartnerId,
      );

      showDialog(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          const accent = Color(0xFFFFFF00);

          return BulletinDialogShell(
            accent: accent,
            title: Text(
              'ATTACK DOG CONVERSION',
              style: ClubBlackoutTheme.headingStyle.copyWith(color: accent),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 60, color: accent),
                const SizedBox(height: 12),
                Text(
                  'Did ${obsession.name} call ${clinger.name} a "controller"?',
                  style: TextStyle(fontSize: 16, color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _convertToAttackDog(clinger);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.18),
                  foregroundColor: accent,
                  side: const BorderSide(color: accent, width: 1.5),
                ),
                icon: const Icon(Icons.check),
                label: const Text('YES, CONVERT'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing attack dog conversion: $e');
    }
  }

  void _convertToAttackDog(Player clinger) {
    clinger.clingerFreedAsAttackDog = true;
    widget.gameEngine.logAction(
      'Attack Dog Conversion',
      '${clinger.name} has been freed from their obsession and is now an attack dog!',
    );

    final killTargets = sortedPlayersByDisplayName(
      widget.gameEngine.players
          .where((p) => p.isActive && p.id != clinger.id && !p.joinsNextNight)
          .toList(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        const accent = Color(0xFFFFFF00);

        return BulletinDialogShell(
          accent: accent,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          title: Text(
            '${clinger.name} IS NOW AN ATTACK DOG',
            style: ClubBlackoutTheme.headingStyle.copyWith(color: accent),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: ListView(
                  children: killTargets
                      .map(
                        (player) => PlayerTile(
                          player: player,
                          gameEngine: widget.gameEngine,
                          onTap: () {
                            Navigator.pop(context);
                            _executeAttackDogKill(clinger, player);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() {});
  }

  void _executeAttackDogKill(Player clinger, Player victim) {
    clinger.clingerAttackDogUsed = true;
    widget.gameEngine.processDeath(victim, cause: 'attack_dog_kill');
    widget.gameEngine.logAction(
      'Attack Dog Kill',
      '${clinger.name} (attack dog) killed ${victim.name}!',
    );
    setState(() {});
  }

  void _showLog() {
    showDialog(
      context: context,
      builder: (context) => _GameLogDialog(gameEngine: widget.gameEngine),
    );
  }

  // ignore: unused_element
  void _showClingerObsessionRole() {
    try {
      final clinger = widget.gameEngine.players.firstWhere(
        (p) => p.role.id == 'clinger',
      );
      if (clinger.clingerPartnerId == null) {
        widget.gameEngine.advanceScript();
        setState(() {});
        return;
      }
      final obsession = widget.gameEngine.players.firstWhere(
        (p) => p.id == clinger.clingerPartnerId,
      );
      final obsessionRole = obsession.role;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OBSESSION REVEAL',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: obsessionRole.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your obsession is: ${obsession.name}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Their Role: ${obsessionRole.name}',
                  style: TextStyle(color: obsessionRole.color),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.gameEngine.advanceScript();
                    setState(() {});
                  },
                  child: const Text('CONFIRM'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      widget.gameEngine.advanceScript();
      setState(() {});
    }
  }

  // ignore: unused_element
  void _showCreepTargetRole() {
    try {
      final creep = widget.gameEngine.players.firstWhere(
        (p) => p.role.id == 'creep',
      );
      if (creep.creepTargetId == null) {
        widget.gameEngine.advanceScript();
        setState(() {});
        return;
      }
      final target = widget.gameEngine.players.firstWhere(
        (p) => p.id == creep.creepTargetId,
      );
      final targetRole = target.role;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CREEP TARGET',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mimicking: ${target.name}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Their Role: ${targetRole.name}',
                  style: TextStyle(color: targetRole.color),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.gameEngine.advanceScript();
                    setState(() {});
                  },
                  child: const Text('CONFIRM'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      widget.gameEngine.advanceScript();
      setState(() {});
    }
  }

  void _showRoleReveal(Player target, String actionTitle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                target.role.name,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: target.role.color,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CONTINUE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOptionGrid(ScriptStep step) {
    List<String> options = [];
    String title = '';
    Color optionColor = ClubBlackoutTheme.neonBlue;

    if (step.id == 'medic_setup_choice') {
      options = ['PROTECT', 'REVIVE'];
      title = 'Choose Your Mode (PERMANENT)';
      optionColor = ClubBlackoutTheme.neonGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: optionColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final cs = Theme.of(context).colorScheme;
              final option = options[index];
              final isSelected = _currentSelection.contains(option);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentSelection.clear();
                      _currentSelection.add(option);
                    });
                    _advanceScript();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? optionColor : cs.outlineVariant,
                        width: isSelected ? 3 : 2,
                      ),
                      color: isSelected
                          ? optionColor.withValues(alpha: 0.2)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: optionColor.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(
                              color: cs.shadow.withValues(alpha: 0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _confirmSkip() {
    showDialog(
      context: context,
      builder: (context) => ClubAlertDialog(
        title: const Text('SKIP TO NEXT PHASE?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.gameEngine.skipToNextPhase();
              setState(() => _currentSelection.clear());
            },
            child: const Text('SKIP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.gameEngine,
      builder: (context, child) {
        _checkScroll();
        _checkAbilityNotifications(); // Check for new ability availability

        final cs = Theme.of(context).colorScheme;

        final steps = widget.gameEngine.scriptQueue;
        final safeIndex = widget.gameEngine.currentScriptIndex.clamp(
          0,
          steps.length,
        );
        final isWaiting = safeIndex >= steps.length;
        final visibleCount = safeIndex + (isWaiting ? 0 : 1);

        ScriptStep? currentStep;
        if (!isWaiting && steps.isNotEmpty) {
          currentStep = steps[safeIndex];
        }

        return Scaffold(
          key: _scaffoldKey,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cs.scrim.withValues(alpha: 0.7),
                        cs.scrim.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu, color: cs.onSurface, size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip: 'Game Menu',
                );
              },
            ),
            title: const Text('CLUB BLACKOUT'),
            centerTitle: true,
            actions: [
              IconButton(
                icon:
                    Icon(Icons.history_rounded, color: cs.onSurface, size: 24),
                onPressed: _showLog,
                tooltip: 'Game Log',
              ),
            ],
          ),
          drawer: GameDrawer(
            gameEngine: widget.gameEngine,
            onGameLogTap: _showLog,
            onHostDashboardTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      HostOverviewScreen(gameEngine: widget.gameEngine),
                ),
              );
            },
            onNavigate: (index) {
              Navigator.pop(context); // Close drawer
              // For GameScreen, we probably want to leave and go to home?
              if (index == 0) {
                Navigator.pop(context);
              }
            },
          ),
          body: Stack(
            children: [
              // Enhanced background with overlay
              Positioned.fill(
                child: Stack(
                  children: [
                    Image.asset(
                      'Backgrounds/Club Blackout V2 Game Background.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          Container(color: Theme.of(c).colorScheme.surface),
                    ),
                    // Dark overlay for better text contrast
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            cs.scrim.withValues(alpha: 0.3),
                            cs.scrim.withValues(alpha: 0.15),
                            cs.scrim.withValues(alpha: 0.4),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (steps.isNotEmpty && !isWaiting)
                Positioned.fill(
                  child: SafeArea(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 88, bottom: 200),
                      itemCount: visibleCount,
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        final isLast = index == visibleCount - 1;

                        // Ensure GlobalKey exists for this index
                        _stepKeys.putIfAbsent(index, () => GlobalKey());
                        final key = _stepKeys[index]!;

                        // Day Phase Integration
                        if (step.id.startsWith('day_start_discussion')) {
                          return _buildDayPhaseLauncher(step);
                        }
                        if (step.id == 'day_vote') {
                          // Automatically handled by the DaySceneDialog logic
                          return const SizedBox.shrink();
                        }

                        if (step.actionType ==
                            ScriptActionType.phaseTransition) {
                          return PhaseCard(
                            key: key,
                            phaseName:
                                step.isNight ? 'PARTY TIME!' : 'CLUB IS CLOSED',
                            subtitle: step.id == 'club_closed'
                                ? step.readAloudText
                                : null,
                            phaseColor: step.isNight
                                ? ClubBlackoutTheme.neonPurple
                                : ClubBlackoutTheme.neonOrange,
                            phaseIcon: step.isNight
                                ? Icons.nightlight_round
                                : Icons.wb_sunny,
                            isActive: isLast,
                          );
                        }

                        final role = widget.gameEngine.roleRepository
                            .getRoleById(step.roleId ?? '');

                        // Find the player with this role
                        Player? player;
                        if (role != null) {
                          try {
                            player = widget.gameEngine.players.firstWhere(
                              (p) =>
                                  p.role.id == role.id &&
                                  p.isActive &&
                                  !p.soberSentHome,
                            );
                          } catch (_) {}
                        }

                        return Column(
                          key: key,
                          children: [
                            InteractiveScriptCard(
                              step: step,
                              isActive: isLast,
                              stepColor:
                                  role?.color ?? ClubBlackoutTheme.neonOrange,
                              role: role,
                              playerName: player?.name,
                              player: player,
                              gameEngine: widget.gameEngine,
                            ),
                            if (isLast && step.id == 'day_vote')
                              _buildVotingGrid(step),
                            if (isLast &&
                                (step.actionType ==
                                        ScriptActionType.selectPlayer ||
                                    step.actionType ==
                                        ScriptActionType.selectTwoPlayers) &&
                                step.id != 'day_vote')
                              _buildPlayerSelectionList(step),
                            if (isLast &&
                                step.actionType ==
                                    ScriptActionType.toggleOption)
                              _buildToggleOptionGrid(step),
                            if (isLast &&
                                step.actionType ==
                                    ScriptActionType.binaryChoice)
                              _buildBinaryChoice(step),
                            if (isLast &&
                                step.actionType == ScriptActionType.showInfo)
                              _buildShowInfoAction(step),
                          ],
                        );
                      },
                    ),
                  ),
                )
              else if (isWaiting)
                const Center(
                  child: Text(
                    'Phase Complete',
                    style: TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
              if (!isWaiting && currentStep != null)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: _buildFloatingActionBar(currentStep),
                ),
              if (isWaiting)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FilledButton(
                      onPressed: _advanceScript,
                      child: const Text('CONTINUE'),
                    ),
                  ),
                ),
              if (_abilityFabExpanded) _buildAbilityFabMenu(),
              if (_rumourMillExpanded)
                Positioned.fill(child: _buildRumourMillPanel()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionBar(ScriptStep step) {
    final cs = Theme.of(context).colorScheme;

    // Hide forward button during player selection steps
    final isSelectionStep = (step.actionType == ScriptActionType.selectPlayer ||
            step.actionType == ScriptActionType.selectTwoPlayers) &&
        step.id != 'day_vote';
    final isSelectionReady = !isSelectionStep || _isSelectionValidForStep(step);

    // Recalculate ability availability for the FAB visibility
    final hasMessyBitch = widget.gameEngine.players.any(
      (p) => p.role.id == 'messy_bitch',
    );
    final hasLightweight = widget.gameEngine.players.any(
      (p) => p.role.id == 'lightweight' && p.isActive,
    );
    final hasClingerToFree = widget.gameEngine.players.any(
      (p) =>
          p.role.id == 'clinger' &&
          p.isActive &&
          p.clingerPartnerId != null &&
          !p.clingerAttackDogUsed,
    );
    final hasSecondWindConversion = widget.gameEngine.players.any(
      (p) =>
          p.role.id == 'second_wind' &&
          p.secondWindPendingConversion &&
          !p.secondWindConverted,
    );
    final hasTeaSpiller = widget.gameEngine.players.any(
      (p) => p.role.id == 'tea_spiller',
    );
    final hasPredator = widget.gameEngine.players.any(
      (p) => p.role.id == 'predator',
    );
    final hasDramaQueen = widget.gameEngine.dramaQueenSwapPending;
    final hasMedic = widget.gameEngine.players.any(
      (p) =>
          p.role.id == 'medic' &&
          p.isActive &&
          p.medicChoice == 'REVIVE' &&
          !p.hasReviveToken,
    );
    final hasSober = widget.gameEngine.players.any(
      (p) => p.role.id == 'sober' && p.isActive,
    );
    final hasBouncer = widget.gameEngine.players.any(
      (p) => p.role.id == 'bouncer' && p.isActive && !p.bouncerAbilityRevoked,
    );

    final hasAnyAbility = hasMessyBitch ||
        hasLightweight ||
        hasClingerToFree ||
        hasSecondWindConversion ||
        hasTeaSpiller ||
        hasPredator ||
        hasDramaQueen ||
        hasMedic ||
        hasSober ||
        hasBouncer;

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHigh.withValues(alpha: 0.78),
            cs.surfaceContainerHighest.withValues(alpha: 0.86),
          ],
        ),
        border: Border.all(
          color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Back Button
          _buildBottomBarButton(
            icon: Icons.arrow_back_rounded,
            onPressed: widget.gameEngine.regressScript,
            color: ClubBlackoutTheme.neonBlue,
            tooltip: 'Back',
          ),

          // 2. FAB Menu (Lightning Bolt)
          if (hasAnyAbility)
            GestureDetector(
              onTap: () =>
                  setState(() => _abilityFabExpanded = !_abilityFabExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ClubBlackoutTheme.neonPurple.withValues(alpha: 0.5),
                      ClubBlackoutTheme.neonPurple.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: _abilityFabExpanded
                      ? [
                          BoxShadow(
                            color: ClubBlackoutTheme.neonPurple
                                .withValues(alpha: 0.8),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: ClubBlackoutTheme.neonPurple
                                .withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: ClubBlackoutTheme.neonPurple
                                .withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 64),

          // 3. Skip Button (Fast Forward)
          _buildBottomBarButton(
            icon: Icons.fast_forward_rounded,
            onPressed: _confirmSkip,
            color: ClubBlackoutTheme.neonOrange,
            tooltip: 'Skip',
          ),

          // 4. Confirm/Advance Button (Tick)
          _buildBottomBarButton(
            icon: Icons.check_rounded,
            onPressed: isSelectionReady ? _advanceScript : null,
            color: isSelectionReady ? ClubBlackoutTheme.neonGreen : Colors.grey,
            tooltip: isSelectionStep
                ? (isSelectionReady
                    ? 'Confirm selection'
                    : (step.actionType == ScriptActionType.selectTwoPlayers
                        ? 'Select 2 players first'
                        : 'Select a player first'))
                : 'Confirm',
          ),
        ],
      ),
    );
  }

  bool _isSelectionValidForStep(ScriptStep step) {
    if (step.actionType == ScriptActionType.selectTwoPlayers) {
      return _currentSelection.length == 2;
    }
    if (step.actionType == ScriptActionType.selectPlayer) {
      return _currentSelection.isNotEmpty;
    }
    return true;
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    required String tooltip,
  }) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isEnabled
              ? RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.5),
                    color.withValues(alpha: 0.2),
                  ],
                )
              : null,
          color: isEnabled ? null : Colors.grey.withValues(alpha: 0.3),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 26),
          style: IconButton.styleFrom(
            foregroundColor: isEnabled ? Colors.white : Colors.grey,
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildVotingGrid(ScriptStep step) {
    // Exclude players sent home by Sober from the voting list
    final players = sortedPlayersByDisplayName(
      widget.gameEngine.players
          .where((p) => p.isAlive && !p.soberSentHome)
          .toList(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: players.map((player) {
          final votes = _voteCounts[player.id] ?? 0;
          return Row(
            children: [
              Expanded(
                child: PlayerTile(
                  player: player,
                  gameEngine: widget.gameEngine,
                  voteCount: votes,
                  onTap: () =>
                      setState(() => _voteCounts[player.id] = votes + 1),
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white54),
                    onPressed: () =>
                        setState(() => _voteCounts[player.id] = votes + 1),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white24,
                    ),
                    onPressed: () => setState(
                      () => _voteCounts[player.id] = max(0, votes - 1),
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerSelectionList(ScriptStep step) {
    final cs = Theme.of(context).colorScheme;

    final allowSentHomeTargets = step.id == 'dealer_act' ||
        step.id == 'medic_act' ||
        step.id == 'medic_protect' ||
        step.id == 'bouncer_act' ||
        step.id == 'roofi_act' ||
        step.id == 'club_manager_act';

    // Usually sent-home players are unavailable for the night. However, some roles
    // are allowed to *choose* them (and the effect will fail / be wasted).
    final players = sortedPlayersByDisplayName(
      widget.gameEngine.players
          .where(
            (p) => p.isAlive && (allowSentHomeTargets || !p.soberSentHome),
          )
          .toList(),
    );

    final role =
        widget.gameEngine.roleRepository.getRoleById(step.roleId ?? '');
    final accent = role?.color ?? ClubBlackoutTheme.neonPurple;
    final required =
        step.actionType == ScriptActionType.selectTwoPlayers ? 2 : 1;
    final selectedNames = _currentSelection
        .map(
          (id) => widget.gameEngine.players.firstWhere((p) => p.id == id).name,
        )
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.45),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  required == 2
                      ? Icons.group_add_rounded
                      : Icons.person_search_rounded,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select $required player${required == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: cs.shadow.withValues(alpha: 0.55),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedNames.isEmpty
                            ? 'Tap a name to choose.'
                            : 'Selected (${selectedNames.length}/$required): ${selectedNames.join(', ')}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'No eligible players to select.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                final isSelected = _currentSelection.contains(p.id);

                String stats = '';
                if (p.role.id == 'clinger' && p.clingerPartnerId != null) {
                  final partner = widget.gameEngine.players.firstWhere(
                    (pl) => pl.id == p.clingerPartnerId,
                    orElse: () => p,
                  );
                  stats = 'Obsession: ${partner.name}';
                } else if (p.role.id == 'creep' && p.creepTargetId != null) {
                  final target = widget.gameEngine.players.firstWhere(
                    (pl) => pl.id == p.creepTargetId,
                    orElse: () => p,
                  );
                  stats = 'Mimicking: ${target.role.name}';
                } else if (p.role.id == 'tea_spiller' &&
                    p.teaSpillerTargetId != null) {
                  final target = widget.gameEngine.players.firstWhere(
                    (pl) => pl.id == p.teaSpillerTargetId,
                    orElse: () => p,
                  );
                  stats = 'Target: ${target.name}';
                } else if (p.role.id == 'predator' &&
                    p.predatorTargetId != null) {
                  final prey = widget.gameEngine.players.firstWhere(
                    (pl) => pl.id == p.predatorTargetId,
                    orElse: () => p,
                  );
                  stats = 'Prey: ${prey.name}';
                }

                return NightPhasePlayerTile(
                  player: p,
                  isSelected: isSelected,
                  gameEngine: widget.gameEngine,
                  statsText: stats,
                  onTap: () {
                    // Standard selection toggle
                    _onPlayerSelected(p.id);
                  },
                  onConfirm: null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBinaryChoice(ScriptStep step) {
    if (step.id == 'second_wind_decision') {
      final secondWind = widget.gameEngine.players.firstWhere(
        (p) => p.role.id == 'second_wind',
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  widget.gameEngine.logAction(
                    'Second Wind Decision',
                    'Dealers chose NOT to convert. Second Wind dies.',
                  );
                  _refuseSecondWindConversion(secondWind);
                  widget.gameEngine.advanceScript();
                  _scrollToBottom();
                },
                icon: const Icon(Icons.close),
                label: const Text('NO (KILL)'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  widget.gameEngine.logAction(
                    'Second Wind Decision',
                    'Dealers chose to convert ${secondWind.name}.',
                  );
                  _acceptSecondWindConversion(secondWind);
                  widget.gameEngine.advanceScript();
                  _scrollToBottom();
                },
                icon: const Icon(Icons.check),
                label: const Text('YES (CONVERT)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFDE3163,
                  ).withValues(alpha: 0.2), // Second Wind Pink
                  foregroundColor: const Color(0xFFDE3163),
                  side: const BorderSide(color: Color(0xFFDE3163), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildShowInfoAction(ScriptStep step) {
    if (step.id != 'clinger_reveal' && step.id != 'creep_reveal') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: FilledButton.icon(
          onPressed: () => _handleShowInfoAction(step),
          icon: const Icon(Icons.visibility),
          label: const Text('REVEAL INFORMATION'),
          style: ClubBlackoutTheme.neonButtonStyle(Colors.white),
        ),
      ),
    );
  }

  void _handleShowInfoAction(ScriptStep step) {
    if (step.id == 'clinger_reveal') {
      final targetId = widget.gameEngine.nightActions['clinger_obsession'];
      if (targetId != null) {
        final target = widget.gameEngine.players.firstWhere(
          (p) => p.id == targetId,
          orElse: () => widget.gameEngine.players.first,
        );
        _showClingerConfirmation(target);
      }
    } else if (step.id == 'creep_reveal') {
      final targetId = widget.gameEngine.nightActions['creep_target'] ??
          widget.gameEngine.nightActions['creep_act'];
      if (targetId != null) {
        final target = widget.gameEngine.players.firstWhere(
          (p) => p.id == targetId,
          orElse: () => widget.gameEngine.players.first,
        );
        _showCreepConfirmation(target);
      }
    }
  }

  void _checkAbilityNotifications() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final abilities = <Map<String, dynamic>>[
        {
          'id_base': 'messy_bitch_ready',
          'condition': widget.gameEngine.players.any(
            (p) => p.role.id == 'messy_bitch' && p.isActive,
          ),
          'msg': 'Messy Bitch: Rumour Mill is active! Open FAB to view.',
        },
        {
          'id_base': 'clinger_attack_ready',
          'condition': widget.gameEngine.players.any(
            (p) =>
                p.role.id == 'clinger' &&
                p.isActive &&
                p.clingerPartnerId != null &&
                !p.clingerAttackDogUsed,
          ),
          'msg': 'Clinger Notification: Attack Dog ability available!',
        },
        {
          'id_base': 'second_wind_ready',
          'condition': widget.gameEngine.players.any(
            (p) =>
                p.role.id == 'second_wind' &&
                p.secondWindPendingConversion &&
                !p.secondWindConverted,
          ),
          'msg': 'Second Wind Notification: Conversion opportunity available!',
        },
        {
          'id_base': 'silver_fox_ready',
          'condition': false,
          'msg': 'Silver Fox disabled.',
        },
        {
          'id_base': 'tea_spiller_ready',
          'condition': widget.gameEngine.players.any(
            (p) =>
                p.role.id == 'tea_spiller' &&
                widget.gameEngine.deadPlayerIds.contains(p.id),
          ),
          'msg': 'Tea Spiller DIED: Check menu for Tea Spilling opportunity.',
        },
        {
          'id_base': 'predator_ready',
          'condition': widget.gameEngine.players.any(
            (p) =>
                p.role.id == 'predator' &&
                widget.gameEngine.deadPlayerIds.contains(p.id),
          ),
          'msg': 'Predator DIED: Check menu for Retaliation opportunity.',
        },
        {
          'id_base': 'drama_queen_ready',
          'condition': widget.gameEngine.dramaQueenSwapPending,
          'msg': 'Drama Queen died: swap two players now.',
        },
        {
          'id_base': 'medic_ready',
          'condition': widget.gameEngine.players.any(
            (p) =>
                p.role.id == 'medic' &&
                p.isActive &&
                p.medicChoice == 'REVIVE' &&
                !p.hasReviveToken,
          ),
          'msg': 'Medic: Revive ability is available.',
        },
        {
          'id_base': 'bouncer_ready',
          'condition': widget.gameEngine.players.any(
            (p) =>
                p.role.id == 'bouncer' &&
                p.isActive &&
                !p.bouncerAbilityRevoked,
          ),
          'msg': 'The Bouncer: Confront Roofi ability available.',
        },
      ];

      // Prime on first pass to avoid firing notifications immediately at game start
      if (!_abilityNotificationsPrimed) {
        for (final ab in abilities) {
          final idBase = ab['id_base'] as String;
          final bool condition = ab['condition'] == true;
          _abilityLastState[idBase] = condition;
        }
        _abilityNotificationsPrimed = true;
        return;
      }

      for (final ab in abilities) {
        final bool condition = ab['condition'] == true;
        final String idBase = ab['id_base'] as String;
        final String message = ab['msg'] as String;

        final bool wasActive = _abilityLastState[idBase] ?? false;
        _abilityLastState[idBase] = condition;

        // Notify only on transition from inactive -> active, and only once per activation
        if (condition &&
            !wasActive &&
            !_shownAbilityNotifications.contains(idBase)) {
          _shownAbilityNotifications.add(idBase);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.notification_important,
                    color: ClubBlackoutTheme.neonOrange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  Theme.of(context).colorScheme.inverseSurface.withValues(
                        alpha: 0.92,
                      ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: ClubBlackoutTheme.neonOrange),
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OPEN MENU',
                textColor: ClubBlackoutTheme.neonOrange,
                onPressed: () {
                  setState(() {
                    _abilityFabExpanded = true;
                  });
                },
              ),
            ),
          );
        }
      }
    });
  }

  Widget _buildAbilityFabMenu() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Messy Bitch -> Rumour Mill (Info/Tool) - Active when Alive
            if (widget.gameEngine.players.any(
              (p) => p.role.id == 'messy_bitch' && p.isActive,
            ))
              _buildNeonFabParam(
                roleId: 'messy_bitch',
                onPressed: () => setState(() => _rumourMillExpanded = true),
              ),

            // Clinger -> Attack Dog (Manual Activation) - Active when Linked
            if (widget.gameEngine.players.any(
              (p) =>
                  p.role.id == 'clinger' &&
                  p.isActive &&
                  p.clingerPartnerId != null &&
                  !p.clingerAttackDogUsed,
            ))
              _buildNeonFabParam(
                roleId: 'clinger',
                onPressed: _showAttackDogConversion,
              ),

            // Second Wind -> Conversion (Manual Activation) - Active Pending
            if (widget.gameEngine.players.any(
              (p) =>
                  p.role.id == 'second_wind' &&
                  p.secondWindPendingConversion &&
                  !p.secondWindConverted,
            ))
              _buildNeonFabParam(
                roleId: 'second_wind',
                onPressed: _showSecondWindConversion,
              ),

            // Silver Fox disabled (host request)

            // Lightweight -> Taboo List (Info) - Active when Alive
            if (widget.gameEngine.players.any(
              (p) => p.role.id == 'lightweight' && p.isActive,
            ))
              _buildNeonFabParam(
                roleId: 'lightweight',
                onPressed: _showTabooList,
              ),

            // Tea Spiller -> Reveal (Death Reaction) - ONLY ACTIVE WHEN DEAD
            if (widget.gameEngine.players.any(
              (p) =>
                  p.role.id == 'tea_spiller' &&
                  widget.gameEngine.deadPlayerIds.contains(p.id),
            ))
              _buildNeonFabParam(
                roleId: 'tea_spiller',
                onPressed: _showTeaSpillerRevealDialog,
              ),

            // Drama Queen -> Swap (Death Reaction) - Active while pending
            if (widget.gameEngine.dramaQueenSwapPending)
              _buildNeonFabParam(
                roleId: 'drama_queen',
                onPressed: _showDramaQueenSwapDialog,
              ),

            // Medic -> Revive (Manual Activation - if Mode Correct) - Active when Alive
            if (widget.gameEngine.players.any(
              (p) =>
                  p.role.id == 'medic' &&
                  widget.gameEngine.deadPlayerIds.contains(p.id) &&
                  (p.medicChoice ?? '').toUpperCase() == 'REVIVE' &&
                  !p.reviveUsed &&
                  p.deathDay == widget.gameEngine.dayCount &&
                  widget.gameEngine.currentPhase == GamePhase.night,
            ))
              _buildNeonFabParam(
                roleId: 'medic',
                onPressed: _showMedicSelfReviveDialog,
              ),

            // Bouncer -> Confront Roofi (Manual Activation)
            if (widget.gameEngine.players.any(
              (p) =>
                  p.role.id == 'bouncer' &&
                  p.isActive &&
                  !p.bouncerAbilityRevoked &&
                  !p.bouncerHasRoofiAbility,
            ))
              _buildNeonFabParam(
                roleId: 'bouncer',
                onPressed: _showBouncerConfrontDialog,
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonFabParam({
    required String roleId,
    required VoidCallback onPressed,
  }) {
    final player = widget.gameEngine.players.firstWhere(
      (p) => p.role.id == roleId,
      orElse: () => widget.gameEngine.players.first,
    );
    final color = player.role.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() => _abilityFabExpanded = false);
          onPressed();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: color, width: 2),
          ),
          child: ClipOval(
            child: player.role.assetPath.isNotEmpty
                ? Image.asset(player.role.assetPath, fit: BoxFit.cover)
                : Icon(Icons.help, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildRumourMillPanel() {
    final cs = Theme.of(context).colorScheme;

    final messyBitch = widget.gameEngine.players.firstWhere(
      (p) => p.role.id == 'messy_bitch',
    );
    final alivePlayers = sortedPlayersByDisplayName(
      widget.gameEngine.players
          .where((p) => p.isActive && p.id != messyBitch.id),
    );
    final heardCount = alivePlayers.where((p) => p.hasRumour).length;
    final totalTargets = alivePlayers.length;

    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Text(
            'RUMOUR MILL',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$heardCount / $totalTargets Targets Reached',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalTargets > 0 ? heardCount / totalTargets : 0,
            backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            color: ClubBlackoutTheme.neonGreen,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: alivePlayers.length,
              itemBuilder: (context, index) {
                final p = alivePlayers[index];
                final hasHeard = p.hasRumour;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: hasHeard
                        ? ClubBlackoutTheme.neonGreen.withValues(alpha: 0.1)
                        : cs.surfaceContainerHigh.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasHeard
                          ? ClubBlackoutTheme.neonGreen
                          : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: hasHeard
                            ? ClubBlackoutTheme.neonGreen
                            : cs.surfaceContainerHighest,
                        child: Icon(
                          hasHeard ? Icons.campaign : Icons.hearing_disabled,
                          color: hasHeard ? Colors.black : cs.onSurface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              hasHeard ? 'Has heard the rumour' : 'Uninformed',
                              style: TextStyle(
                                color: hasHeard
                                    ? ClubBlackoutTheme.neonGreen
                                    : cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasHeard)
                        const Icon(
                          Icons.check_circle,
                          color: ClubBlackoutTheme.neonGreen,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ClubBlackoutTheme.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => setState(() => _rumourMillExpanded = false),
            child: const Text(
              'CLOSE RUMOUR MILL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showBouncerConfrontDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;

        return BulletinDialogShell(
          accent: ClubBlackoutTheme.neonBlue,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          title: Text(
            'CONFRONT THE ROOFI',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonBlue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Does the Bouncer suspect someone? Select their target.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(ClubBlackoutTheme.radiusMd),
                  border: Border.all(
                    color: cs.error.withValues(alpha: 0.45),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: cs.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RISK: If Bouncer is wrong, they lose their I.D. checking ability forever.',
                          style: TextStyle(color: cs.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView(
                  children: widget.gameEngine.players
                      .where((p) => p.isActive && p.role.id != 'bouncer')
                      .map(
                        (p) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.role.color,
                            child: Text(
                              p.name[0],
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          title: Text(p.name),
                          onTap: () {
                            Navigator.pop(context);
                            _processBouncerConfrontation(p);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  void _processBouncerConfrontation(Player target) {
    final ok = widget.gameEngine.resolveBouncerRoofiChallenge(target.id);
    if (!ok) {
      _showBouncerResultDialog(
        'UNAVAILABLE',
        'The Bouncer cannot challenge right now.',
        Colors.orange,
      );
      return;
    }

    final activeBouncers = widget.gameEngine.players
        .where((p) => p.role.id == 'bouncer' && p.isActive)
        .toList();
    final bouncer = activeBouncers.isNotEmpty ? activeBouncers.first : null;

    if (bouncer != null && bouncer.bouncerHasRoofiAbility) {
      _showBouncerResultDialog(
        'SUCCESS',
        'You caught The Roofi!\nTheir power is neutralized — and the Bouncer stole it.',
        ClubBlackoutTheme.neonGreen,
      );
      return;
    }

    if (bouncer != null && bouncer.bouncerAbilityRevoked) {
      _showBouncerResultDialog(
        'FAILURE',
        'That was not The Roofi.\nYou have lost your I.D. checking ability.',
        Colors.red,
      );
      return;
    }

    _showBouncerResultDialog(
      'RESOLVED',
      'The challenge has been resolved.',
      ClubBlackoutTheme.neonBlue,
    );
  }

  void _showBouncerResultDialog(String title, String body, Color color) {
    showDialog(
      context: context,
      builder: (context) {
        return BulletinDialogShell(
          accent: color,
          title: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          content: Text(body),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showTeaSpillerRevealDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;

        return BulletinDialogShell(
          accent: ClubBlackoutTheme.neonOrange,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          title: Text(
            'TEA SPILLER REVEAL',
            style: ClubBlackoutTheme.headingStyle.copyWith(
              color: ClubBlackoutTheme.neonOrange,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'The Tea Spiller has died. Select a player to reveal their role.',
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: ListView(
                  children: widget.gameEngine.players
                      .map(
                        (p) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.role.color,
                            child: Text(
                              p.name[0],
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            p.role.name,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          /* Host sees roles */
                          onTap: () {
                            Navigator.pop(context);
                            widget.gameEngine.logAction(
                              'Tea Spiller Reveal',
                              'Tea Spiller revealed ${p.name} as ${p.role.name}.',
                            );
                            showRoleReveal(
                              context,
                              p.role,
                              p.name,
                              subtitle: 'Tea Spilled by the Dead!',
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void _showDramaQueenSwapDialog() {
    final alivePlayers = sortedPlayersByDisplayName(
        widget.gameEngine.players.where((p) => p.isAlive));
    final initialSelected = <String>{};
    if (widget.gameEngine.dramaQueenMarkedAId != null) {
      initialSelected.add(widget.gameEngine.dramaQueenMarkedAId!);
    }
    if (widget.gameEngine.dramaQueenMarkedBId != null) {
      initialSelected.add(widget.gameEngine.dramaQueenMarkedBId!);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final selected = <String>{...initialSelected};
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final cs = Theme.of(context).colorScheme;
            final gridHeight =
                min(420.0, MediaQuery.sizeOf(context).height * 0.48);

            return BulletinDialogShell(
              accent: ClubBlackoutTheme.neonPurple,
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              title: Text(
                'DRAMA QUEEN SWAP',
                style: ClubBlackoutTheme.headingStyle.copyWith(
                  color: ClubBlackoutTheme.neonPurple,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drama Queen is dead. Pick two players to swap devices, then confirm.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: alivePlayers.length,
                      itemBuilder: (context, index) {
                        final player = alivePlayers[index];
                        final isSelected = selected.contains(player.id);
                        return PlayerTile(
                          gameEngine: widget.gameEngine,
                          player: player,
                          isCompact: true,
                          isSelected: isSelected,
                          onTap: () {
                            setStateDialog(() {
                              if (isSelected) {
                                selected.remove(player.id);
                              } else if (selected.length < 2) {
                                selected.add(player.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ClubBlackoutTheme.neonPurple,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        cs.onSurface.withValues(alpha: 0.38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: selected.length == 2
                      ? () async {
                          final ids = selected.toList();
                          final p1 = alivePlayers.firstWhere(
                            (p) => p.id == ids[0],
                          );
                          final p2 = alivePlayers.firstWhere(
                            (p) => p.id == ids[1],
                          );

                          widget.gameEngine.completeDramaQueenSwap(
                            p1,
                            p2,
                          );
                          Navigator.pop(context);

                          await runSwapTriggeredSetup(
                            context: this.context,
                            gameEngine: widget.gameEngine,
                            swappedPlayers: [p1, p2],
                          );

                          showDialog(
                            context: this.context,
                            builder: (ctx) {
                              final cs2 = Theme.of(ctx).colorScheme;
                              return BulletinDialogShell(
                                accent: ClubBlackoutTheme.neonPurple,
                                title: const Text('SWAP COMPLETE'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${p1.name} is now ${p1.role.name}'),
                                    const SizedBox(height: 8),
                                    Text('${p2.name} is now ${p2.role.name}'),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Host instructions:\n1) Ask all players to close their eyes.\n2) Swap the devices/cards.\n3) Give everyone 10 seconds to check their role.\n4) Resume into the next night.',
                                      style: TextStyle(
                                        color: cs2.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('ACKNOWLEDGE'),
                                  ),
                                ],
                              );
                            },
                          );
                          setState(() {});
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('CONFIRM SWAP'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDayPhaseLauncher(ScriptStep step) {
    // Determine if this specific step is currently active
    final isActive = widget.gameEngine.currentScriptStep?.id == step.id;

    if (!isActive) {
      return const Card(
        color: Colors.white10,
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.white30),
              SizedBox(width: 16),
              Text(
                'Day Phase Completed',
                style: TextStyle(color: Colors.white30, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            final navigator = Navigator.of(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => DaySceneDialog(
                gameEngine: widget.gameEngine,
                selectedNavIndex: 0,
                onNavigate: (index) {
                  navigator.pop(); // close dialog
                  if (index == 0) {
                    navigator.pop(); // return to previous screen (home)
                  }
                },
                onGameLogTap: () {
                  navigator.pop(); // close dialog
                  _showLog();
                },
                onComplete: () {
                  // Advance through all remaining day phase steps (summary, discussion, vote)
                  // The dialog handles them together as one cohesive day phase
                  int safety = 0;
                  do {
                    widget.gameEngine.advanceScript();
                    safety++;
                  } while (safety < 10 &&
                      widget.gameEngine.currentPhase == GamePhase.day &&
                      widget.gameEngine.currentScriptStep != null &&
                      widget.gameEngine.currentScriptStep!.isNight == false);
                  _scrollToBottom();
                },
                onGameEnd: (winner, message) {
                  navigator.pop(); // Close dialog
                  _showGameEndDialog(winner, message);
                },
              ),
            );
          },
          icon: const Icon(Icons.meeting_room, size: 28),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('BEGIN DAY PHASE', style: TextStyle(fontSize: 20)),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: ClubBlackoutTheme.neonOrange,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
          ),
        ),
      ),
    );
  }
}

enum _LogFilter { all, action, system, script }

class _GameLogDialog extends StatefulWidget {
  final GameEngine gameEngine;
  const _GameLogDialog({required this.gameEngine});

  @override
  State<_GameLogDialog> createState() => _GameLogDialogState();
}

class _GameLogDialogState extends State<_GameLogDialog> {
  _LogFilter _filter = _LogFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _groupByPhase = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Color _typeColor(GameLogType type) {
    switch (type) {
      case GameLogType.system:
        return ClubBlackoutTheme.neonOrange;
      case GameLogType.script:
        return ClubBlackoutTheme.neonPurple;
      case GameLogType.action:
        return ClubBlackoutTheme.neonBlue;
    }
  }

  IconData _typeIcon(GameLogType type) {
    switch (type) {
      case GameLogType.system:
        return Icons.settings_rounded;
      case GameLogType.script:
        return Icons.auto_stories_rounded;
      case GameLogType.action:
        return Icons.bolt_rounded;
    }
  }

  List<GameLogEntry> _filteredEntries() {
    final entries = widget.gameEngine.gameLog;
    Iterable<GameLogEntry> filtered;

    // Apply type filter
    switch (_filter) {
      case _LogFilter.action:
        filtered = entries.where((e) => e.type == GameLogType.action);
        break;
      case _LogFilter.system:
        filtered = entries.where((e) => e.type == GameLogType.system);
        break;
      case _LogFilter.script:
        filtered = entries.where((e) => e.type == GameLogType.script);
        break;
      case _LogFilter.all:
        filtered = entries;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
          e.title.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query) ||
          e.phase.toLowerCase().contains(query));
    }

    return filtered.toList(growable: false).reversed.toList(growable: false);
  }

  Map<String, List<GameLogEntry>> _groupedEntries() {
    final entries = _filteredEntries();
    if (!_groupByPhase) return {'all': entries};

    final grouped = <String, List<GameLogEntry>>{};
    for (final entry in entries) {
      final key = 'Turn ${entry.turn} - ${entry.phase.toUpperCase()}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  void _exportLog() {
    final entries = _filteredEntries();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No log entries to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Club Blackout 3 — Game Log');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${entries.length}');
    buffer.writeln('');

    for (final entry in entries.reversed) {
      buffer.writeln('[${entry.timestamp.toIso8601String()}]');
      buffer.writeln(
          'Turn ${entry.turn} — ${entry.phase.toUpperCase()} — ${entry.type.name.toUpperCase()}');
      buffer.writeln(entry.title);
      if (entry.description.trim().isNotEmpty) {
        buffer.writeln(entry.description);
      }
      buffer.writeln('');
    }

    final text = buffer.toString();
    Clipboard.setData(ClipboardData(text: text));

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Export Log'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    _LogFilter value,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      selectedColor: color.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? color : cs.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      side: BorderSide(
        color: selected ? color.withValues(alpha: 0.65) : cs.outlineVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = _filteredEntries();

    return BulletinDialogShell(
      accent: ClubBlackoutTheme.neonBlue,
      maxWidth: 560,
      maxHeight: 640,
      title: Row(
        children: [
          const Icon(
            Icons.history,
            color: ClubBlackoutTheme.neonBlue,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'GAME LOG',
              style: TextStyle(
                fontFamily: 'Hyperwave',
                fontSize: 24,
                color: ClubBlackoutTheme.neonBlue,
                shadows: ClubBlackoutTheme.textGlow(ClubBlackoutTheme.neonBlue),
                letterSpacing: 1.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isSearching = !_isSearching),
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: ClubBlackoutTheme.neonBlue,
            ),
            tooltip: _isSearching ? 'Close search' : 'Search log',
          ),
          IconButton(
            onPressed: _exportLog,
            icon: const Icon(
              Icons.share,
              color: ClubBlackoutTheme.neonGreen,
            ),
            tooltip: 'Export log',
          ),
          Text(
            '${entries.length}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Column(
        children: [
          if (_isSearching) ...[
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: cs.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                        color: cs.onSurfaceVariant,
                      )
                    : null,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ClubBlackoutTheme.neonBlue.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All',
                        _LogFilter.all,
                        ClubBlackoutTheme.neonBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Action',
                        _LogFilter.action,
                        ClubBlackoutTheme.neonBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'System',
                        _LogFilter.system,
                        ClubBlackoutTheme.neonOrange,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Script',
                        _LogFilter.script,
                        ClubBlackoutTheme.neonPurple,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _groupByPhase = !_groupByPhase),
                icon: Icon(
                  _groupByPhase ? Icons.view_list : Icons.view_timeline,
                  color: _groupByPhase
                      ? ClubBlackoutTheme.neonGreen
                      : cs.onSurfaceVariant,
                ),
                tooltip: _groupByPhase ? 'List view' : 'Timeline view',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.receipt_long_rounded,
                          color: cs.onSurface.withValues(alpha: 0.25),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching events found.'
                              : 'No events recorded yet.',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  )
                : _groupByPhase
                    ? _buildTimelineView()
                    : _buildListView(),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: ClubBlackoutTheme.neonBlue,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'CLOSE LOG',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineView() {
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupedEntries();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.expand((group) {
        return [
          // Group header
          Container(
            margin: const EdgeInsets.only(bottom: 12, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClubBlackoutTheme.neonPurple.withValues(alpha: 0.15),
                  ClubBlackoutTheme.neonBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ClubBlackoutTheme.neonPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timeline,
                  color: ClubBlackoutTheme.neonPurple,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.key,
                    style: const TextStyle(
                      color: ClubBlackoutTheme.neonPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${group.value.length}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Group entries
          ...group.value.map((entry) => _buildLogEntry(entry)),
        ];
      }).toList(),
    );
  }

  Widget _buildListView() {
    final entries = _filteredEntries();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildLogEntry(entries[index]),
    );
  }

  Widget _buildLogEntry(GameLogEntry entry) {
    final cs = Theme.of(context).colorScheme;
    final ts = entry.timestamp.toLocal();
    final hh = ts.hour.toString().padLeft(2, '0');
    final mm = ts.minute.toString().padLeft(2, '0');
    final ss = ts.second.toString().padLeft(2, '0');
    final timeLabel = '$hh:$mm:$ss';
    final typeColor = _typeColor(entry.type);
    final typeIcon = _typeIcon(entry.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    size: 18,
                  ),
                  onSelected: (value) => _handleEntryAction(value, entry),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Copy'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Text('Details'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (entry.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.description,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LogMetaChip(label: 'Turn ${entry.turn}'),
                _LogMetaChip(
                  label: entry.phase.toUpperCase(),
                ),
                _LogMetaChip(label: timeLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleEntryAction(String action, GameLogEntry entry) {
    switch (action) {
      case 'copy':
        final text =
            '${entry.title}\n${entry.description}\nTurn ${entry.turn} - ${entry.phase} - ${entry.timestamp}';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry copied to clipboard')),
        );
        break;
      case 'details':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Entry Details'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Title: ${entry.title}'),
                Text('Description: ${entry.description}'),
                Text('Turn: ${entry.turn}'),
                Text('Phase: ${entry.phase}'),
                Text('Type: ${entry.type.toString().split('.').last}'),
                Text('Time: ${entry.timestamp}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class _LogMetaChip extends StatelessWidget {
  final String label;

  const _LogMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PulsingFab extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isExpanded;

  const _PulsingFab({required this.onPressed, required this.isExpanded});

  @override
  State<_PulsingFab> createState() => _PulsingFabState();
}

class _PulsingFabState extends State<_PulsingFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFDE3163,
                ).withValues(alpha: 0.6 + (_animation.value * 0.4)),
                blurRadius: 10 + (_animation.value * 10),
                spreadRadius: 2 + (_animation.value * 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'ability_toggle_pulsing',
            backgroundColor: const Color(0xFFDE3163), // Second Wind Pink
            foregroundColor: Colors.white, // Ensure icon is visible
            onPressed: widget.onPressed,
            child: Icon(widget.isExpanded ? Icons.close : Icons.autorenew),
          ),
        );
      },
    );
  }
}
