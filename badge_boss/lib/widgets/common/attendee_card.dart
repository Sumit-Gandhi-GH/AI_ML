import 'package:flutter/material.dart';
import '../../models/attendee.dart';

class AttendeeCard extends StatelessWidget {
  final Attendee attendee;
  final VoidCallback? onTap;
  final bool showDetails;

  const AttendeeCard({
    super.key,
    required this.attendee,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(theme),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            attendee.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildCategoryBadge(theme),
                      ],
                    ),
                    if (attendee.company != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        attendee.company!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showDetails) ...[
                      const SizedBox(height: 4),
                      Text(
                        attendee.email,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status
              _buildStatusIndicator(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: attendee.isCheckedIn
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: attendee.photoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                attendee.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(theme),
              ),
            )
          : _buildAvatarFallback(theme),
    );
  }

  Widget _buildAvatarFallback(ThemeData theme) {
    return Center(
      child: Text(
        attendee.firstName.isNotEmpty 
            ? attendee.firstName.substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          color: attendee.isCheckedIn
              ? Colors.green
              : theme.colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ThemeData theme) {
    if (attendee.category == 'general') return const SizedBox.shrink();
    
    Color color;
    switch (attendee.category) {
      case 'vip':
        color = Colors.amber;
        break;
      case 'speaker':
        color = Colors.purple;
        break;
      case 'sponsor':
        color = Colors.blue;
        break;
      case 'staff':
        color = Colors.teal;
        break;
      default:
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        attendee.category.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    if (attendee.isCheckedIn) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.green,
          size: 20,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_forward,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }
}
