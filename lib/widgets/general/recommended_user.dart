import 'package:flutter/material.dart';

/// Stylish card used to represent a recommended user with customizable
/// action content supplied by the parent widget.
class RecommendedUser extends StatelessWidget {
  const RecommendedUser({
    super.key,
    required this.displayName,
    required this.subtitle,
    this.tags,
    this.actionArea,
  });

  final String displayName;
  final String subtitle;
  final List<String>? tags;
  final Widget? actionArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarLetter =
        displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';

    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            child: Text(
              avatarLetter,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (tags != null && tags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags!
                  .take(2)
                  .map(
                    (tag) => Chip(
                      label: Text(tag, style: theme.textTheme.labelSmall),
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
          const Spacer(),
          if (actionArea != null) actionArea!,
        ],
      ),
    );
  }
}
