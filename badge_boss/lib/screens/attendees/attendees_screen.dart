import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attendee.dart';
import '../../providers/attendee_provider.dart';
import '../../widgets/common/attendee_card.dart';
import 'attendee_edit_screen.dart';
import 'attendee_import_wizard.dart';

class AttendeesScreen extends StatefulWidget {
  const AttendeesScreen({super.key});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  final _searchController = TextEditingController();
  String _filterCategory = 'all';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Attendee> _applyFilters(List<Attendee> attendees) {
    return attendees.where((a) {
      if (_filterCategory != 'all' && a.category != _filterCategory) {
        return false;
      }
      if (_filterStatus == 'checked_in' && !a.isCheckedIn) {
        return false;
      }
      if (_filterStatus == 'not_checked_in' && a.isCheckedIn) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search and filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<AttendeeProvider>().searchAttendees(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search attendees...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<AttendeeProvider>().clearSearch();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Filters
              Row(
                children: [
                  Expanded(
                    child: _FilterChip(
                      label: 'Category',
                      value: _filterCategory,
                      options: const {
                        'all': 'All Categories',
                        'general': 'General',
                        'vip': 'VIP',
                        'speaker': 'Speaker',
                        'sponsor': 'Sponsor',
                        'staff': 'Staff',
                      },
                      onChanged: (value) {
                        setState(() => _filterCategory = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterChip(
                      label: 'Status',
                      value: _filterStatus,
                      options: const {
                        'all': 'All Status',
                        'checked_in': 'Checked In',
                        'not_checked_in': 'Not Checked In',
                      },
                      onChanged: (value) {
                        setState(() => _filterStatus = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Import',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendeeImportWizard()),
                      ).then((_) => context.read<AttendeeProvider>().refresh());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Add',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendeeEditScreen()),
                      ).then((_) => context.read<AttendeeProvider>().refresh());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Stats summary
        Consumer<AttendeeProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${provider.totalCount} attendees',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${provider.checkedInCount} checked in',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Attendee list
        Expanded(
          child: Consumer<AttendeeProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final attendees = _searchController.text.isNotEmpty
                  ? provider.searchResults
                  : _applyFilters(provider.attendees);

              if (attendees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No attendees found',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: attendees.length,
                  itemBuilder: (context, index) {
                    return AttendeeCard(
                      attendee: attendees[index],
                      showDetails: true,
                      onTap: () {
                        _showAttendeeDetails(context, attendees[index]);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAttendeeDetails(BuildContext context, Attendee attendee) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  attendee.firstName.substring(0, 1),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              attendee.fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (attendee.company != null)
              Text(
                attendee.company!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 8),
            _CategoryBadge(category: attendee.category),
            const SizedBox(height: 24),
            // Details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: attendee.email,
                  ),
                  if (attendee.title != null)
                    _DetailRow(
                      icon: Icons.work_outline,
                      label: 'Title',
                      value: attendee.title!,
                    ),
                  if (attendee.phone != null)
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: attendee.phone!,
                    ),
                  _DetailRow(
                    icon: Icons.qr_code,
                    label: 'QR Code',
                    value: attendee.qrCode,
                  ),
                  _DetailRow(
                    icon: attendee.isCheckedIn
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    label: 'Status',
                    value: attendee.isCheckedIn
                        ? 'Checked in at ${_formatTime(attendee.checkinStatus.checkedInAt)}'
                        : 'Not checked in',
                    valueColor: attendee.isCheckedIn ? Colors.green : null,
                  ),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AttendeeEditScreen(attendee: attendee)),
                        ).then(
                            (_) => context.read<AttendeeProvider>().refresh());
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Print badge
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print Badge'),
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

  String _formatTime(DateTime? time) {
    if (time == null) return 'Unknown';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Row(
              children: [
                Text(e.value),
                if (e.key == value) ...[
                  const Spacer(),
                  Icon(Icons.check, color: theme.colorScheme.primary),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              options[value] ?? value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    switch (category) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
