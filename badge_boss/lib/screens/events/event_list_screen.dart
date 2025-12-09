import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import 'event_create_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final authProvider = context.read<AuthProvider>();
    await context.read<EventProvider>().loadEvents(authProvider.organizationId);
  }

  List<Event> _getFilteredEvents(List<Event> events) {
    var filtered = events;

    if (_filterStatus == 'active') {
      filtered = filtered.where((e) => e.isActive).toList();
    } else if (_filterStatus == 'upcoming') {
      filtered =
          filtered.where((e) => e.startDate.isAfter(DateTime.now())).toList();
    } else if (_filterStatus == 'past') {
      filtered =
          filtered.where((e) => e.endDate.isBefore(DateTime.now())).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((e) =>
              e.name.toLowerCase().contains(query) ||
              (e.venue?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filteredEvents = _getFilteredEvents(provider.events);
                if (filteredEvents.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      return _EventCard(
                        event: filteredEvents[index],
                        onTap: () => _openEvent(filteredEvents[index]),
                        onEdit: () => _editEvent(filteredEvents[index]),
                        onDelete: () => _deleteEvent(filteredEvents[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                    label: 'All',
                    isSelected: _filterStatus == 'all',
                    onTap: () => setState(() => _filterStatus = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Active',
                    isSelected: _filterStatus == 'active',
                    onTap: () => setState(() => _filterStatus = 'active'),
                    color: Colors.green),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Upcoming',
                    isSelected: _filterStatus == 'upcoming',
                    onTap: () => setState(() => _filterStatus = 'upcoming'),
                    color: Colors.blue),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Past',
                    isSelected: _filterStatus == 'past',
                    onTap: () => setState(() => _filterStatus = 'past'),
                    color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy,
              size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'No events match your filters'
                  : 'No events yet',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: _createEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create Event')),
        ],
      ),
    );
  }

  void _createEvent() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EventCreateScreen()))
        .then((_) => _loadEvents());
  }

  void _openEvent(Event event) {
    context.read<EventProvider>().selectEvent(event.id);
    Navigator.of(context).pop();
  }

  void _editEvent(Event event) {
    Navigator.of(context)
        .push(
            MaterialPageRoute(builder: (_) => EventCreateScreen(event: event)))
        .then((_) => _loadEvents());
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true)
      await context.read<EventProvider>().deleteEvent(event.id);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? chipColor
                  : theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected
                    ? chipColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard(
      {required this.event,
      required this.onTap,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isActive =
        event.startDate.isBefore(now) && event.endDate.isAfter(now);
    final isUpcoming = event.startDate.isAfter(now);

    final statusColor =
        isActive ? Colors.green : (isUpcoming ? Colors.blue : Colors.grey);
    final statusText = isActive ? 'Active' : (isUpcoming ? 'Upcoming' : 'Past');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.event, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(statusText,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('Edit')
                          ])),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red))
                          ])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 8),
                  Text(_formatDate(event.startDate),
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13)),
                ],
              ),
              if (event.venue != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(event.venue!,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                      label: 'Registered',
                      value: '${event.stats.totalRegistered}'),
                  _StatColumn(
                      label: 'Checked In', value: '${event.stats.checkedIn}'),
                  _StatColumn(
                      label: 'Capacity',
                      value: event.settings.maxCapacity > 0
                          ? '${event.settings.maxCapacity}'
                          : '∞'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        Text(label,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12)),
      ],
    );
  }
}
