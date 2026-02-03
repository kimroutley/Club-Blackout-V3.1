import 'package:flutter/material.dart';
import '../styles.dart';

class ActiveEventCard extends StatelessWidget {
  final Widget header;
  final Widget? body;
  final Widget? actionSlot;

  const ActiveEventCard({
    super.key,
    required this.header,
    this.body,
    this.actionSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ClubBlackoutTheme.kCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClubBlackoutTheme.kNeonCyan.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ClubBlackoutTheme.kBackground.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: header,
          ),
          
          if (body != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: body,
            ),
            const SizedBox(height: 16),
          ],

          // Action Slot
          if (actionSlot != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: actionSlot,
            ),
        ],
      ),
    );
  }
}
