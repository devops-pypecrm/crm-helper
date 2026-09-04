import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/lead_search_provider.dart';

/// Small UI element shown above the dialer keypad when the entered digits
/// match an existing CRM lead.
class LeadMatchChip extends ConsumerWidget {
  const LeadMatchChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(currentLeadMatchProvider);
    if (match == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            match.name.isNotEmpty ? match.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12,
            ),
          ),
        ),
        label: Text(match.name),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
