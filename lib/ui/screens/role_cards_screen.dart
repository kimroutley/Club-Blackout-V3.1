import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../../services/sound_service.dart';
import '../styles.dart';
import '../widgets/player_icon.dart';
import '../widgets/role_card_widget.dart';
import '../widgets/role_tile_widget.dart';

class RoleCardsScreen extends StatefulWidget {
  final List<Role> roles;
  final bool embedded;
  final bool isNight;

  const RoleCardsScreen({
    super.key,
    required this.roles,
    this.embedded = false,
    this.isNight = false,
  });

  @override
  State<RoleCardsScreen> createState() => _RoleCardsScreenState();
}

class _RoleCardsScreenState extends State<RoleCardsScreen> {
  String _searchQuery = '';
  String _filterAlliance = 'All';

  List<Role> get filteredRoles {
    var filtered = widget.roles;

    // Apply alliance filter
    if (_filterAlliance != 'All') {
      if (_filterAlliance == 'Dealers') {
        filtered =
            filtered.where((r) => r.alliance.contains('Dealer')).toList();
      } else if (_filterAlliance == 'Party Animals') {
        filtered =
            filtered.where((r) => r.alliance.contains('Party Animal')).toList();
      } else if (_filterAlliance == 'Wild Cards') {
        filtered = filtered
            .where((r) =>
                !r.alliance.contains('Dealer') &&
                !r.alliance.contains('Party Animal'))
            .toList();
      }
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Sort roles by alliance
    final dealerTeam =
        filteredRoles.where((r) => r.alliance.contains('Dealer')).toList();
    final partyAnimals = filteredRoles
        .where((r) => r.alliance.contains('Party Animal'))
        .toList();
    final neutrals = filteredRoles
        .where(
          (r) =>
              !r.alliance.contains('Dealer') &&
              !r.alliance.contains('Party Animal'),
        )
        .toList();

    final list = ListView(
      padding: widget.embedded
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.all(20),
      children: [
        if (!widget.embedded) ...[
          _buildHeaderCard(context),
          const SizedBox(height: 20),
        ],
        _buildSearchBar(context),
        const SizedBox(height: 16),
        _buildFilterChips(context),
        const SizedBox(height: 24),
        _buildAllianceGraph(context),
        const SizedBox(height: 24),
        if (dealerTeam.isNotEmpty) ...[
          _buildRoleGrid(
            'Dealers',
            dealerTeam,
            ClubBlackoutTheme.neonRed,
            context,
          ),
          const SizedBox(height: 24),
        ],
        if (partyAnimals.isNotEmpty) ...[
          _buildRoleGrid(
            'Party Animals',
            partyAnimals,
            ClubBlackoutTheme.neonBlue,
            context,
          ),
          const SizedBox(height: 24),
        ],
        if (neutrals.isNotEmpty) ...[
          _buildRoleGrid(
            'Wild cards & neutrals',
            neutrals,
            ClubBlackoutTheme.neonPurple,
            context,
          ),
        ],
        if (filteredRoles.isEmpty) _buildEmptyState(context),
        const SizedBox(height: 32),
      ],
    );

    final width = MediaQuery.sizeOf(context).width;
    final double maxWidth = width >= 1200 ? 1180.0 : 920.0;

    final content = (widget.isNight && !widget.embedded)
        ? SafeArea(child: list)
        : ClubBlackoutTheme.centeredConstrained(
            maxWidth: maxWidth,
            child: list,
          );

    if (widget.embedded) return content;
    return SafeArea(child: content);
  }

  Widget _buildRoleGrid(
    String title,
    List<Role> allianceRoles,
    Color color,
    BuildContext context,
  ) {
    if (allianceRoles.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForAlliance(title),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${allianceRoles.length}',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allianceRoles
                  .map(
                    (role) => RoleTileWidget(
                      role: role,
                      variant: RoleTileVariant.compact,
                      onTap: () => _showRoleDetail(context, role),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAlliance(String title) {
    if (title.contains('Dealer')) return Icons.dangerous_rounded;
    if (title.contains('Party')) return Icons.celebration_rounded;
    return Icons.auto_awesome_rounded;
  }

  void _showRoleDetail(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: ClubBlackoutTheme.dialogInsetPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The Card itself
              RoleCardWidget(role: role, compact: false),

              const SizedBox(height: 20),

              // Close Button with better M3 styling
              Center(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Close'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.7),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.badge_rounded,
                color: cs.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHARACTER ROLES',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover alliances, abilities, and win conditions',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search roles by name or description...',
        prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  unawaited(SoundService().playClick());
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: cs.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final alliances = ['All', 'Dealers', 'Party Animals', 'Wild Cards'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: alliances.map((alliance) {
          final isSelected = _filterAlliance == alliance;
          final color = _getColorForAlliance(alliance);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alliance != 'All')
                    Icon(
                      _getIconForAlliance(alliance),
                      size: 18,
                      color: isSelected
                          ? color
                          : cs.onSurface.withValues(alpha: 0.6),
                    ),
                  if (alliance != 'All') const SizedBox(width: 6),
                  Text(alliance),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                unawaited(SoundService().playSelect());
                setState(() => _filterAlliance = alliance);
              },
              backgroundColor: cs.surfaceContainerHigh,
              selectedColor: color.withValues(alpha: 0.2),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : cs.onSurface,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForAlliance(String alliance) {
    if (alliance.contains('Dealer')) return ClubBlackoutTheme.neonRed;
    if (alliance.contains('Party')) return ClubBlackoutTheme.neonBlue;
    if (alliance.contains('Wild')) return ClubBlackoutTheme.neonPurple;
    return ClubBlackoutTheme.neonPink;
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No roles found',
                style: tt.titleLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filter',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildAllianceGraph(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: cs.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'ALLIANCE STRUCTURE',
                    style: tt.titleLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAllianceRow(
              context,
              Icons.dangerous_rounded,
              'DEALERS',
              'Eliminate all Party Animals',
              ClubBlackoutTheme.neonRed,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                  color: cs.onSurface.withValues(alpha: 0.1), height: 1),
            ),
            _buildAllianceRow(
              context,
              Icons.celebration_rounded,
              'PARTY ANIMALS',
              'Vote out all Dealers',
              ClubBlackoutTheme.neonBlue,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                  color: cs.onSurface.withValues(alpha: 0.1), height: 1),
            ),
            _buildAllianceRow(
              context,
              Icons.auto_awesome_rounded,
              'WILD CARDS',
              'Unique/Secret win conditions',
              ClubBlackoutTheme.neonPurple,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ClubBlackoutTheme.neonOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ClubBlackoutTheme.neonOrange.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: ClubBlackoutTheme.neonOrange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CONVERSION POSSIBILITIES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ClubBlackoutTheme.neonOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildConversionRow(
                    context,
                    'Second Wind',
                    'PARTY ANIMAL → DEALER',
                    'If killed by Dealers, can join them',
                    cs,
                  ),
                  _buildConversionRow(
                    context,
                    'Clinger',
                    'ANY → ATTACK DOG',
                    'If obsession calls them "controller"',
                    cs,
                  ),
                  _buildConversionRow(
                    context,
                    'Creep',
                    'NEUTRAL → MIMIC',
                    'Becomes their chosen target\'s role',
                    cs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllianceRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConversionRow(
    BuildContext context,
    String roleName,
    String conversion,
    String condition,
    ColorScheme cs,
  ) {
    // Find role for icon/color
    Role? role;
    try {
      role = widget.roles.firstWhere((r) {
        final rName = r.name.toLowerCase();
        final qName = roleName.toLowerCase();
        return rName == qName ||
            rName.contains(qName) ||
            qName.contains(rName.replaceAll('the ', ''));
      });
    } catch (_) {}

    final color = role?.color ?? ClubBlackoutTheme.neonOrange;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          PlayerIcon(
            assetPath: role?.assetPath ?? '',
            glowColor: color,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role?.name ?? roleName,
                  style: ClubBlackoutTheme.glowTextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.transform,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conversion,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  condition,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
