import 'package:flutter/material.dart';

/// Small reusable section title used to group related cards on
/// Settings/Home/update screens, instead of each screen hand-rolling its
/// own bold `Text` + `SizedBox` pair.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
