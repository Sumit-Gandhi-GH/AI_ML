import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/attendee_provider.dart';
import '../../providers/sync_provider.dart';
import '../checkin/checkin_screen.dart';
import '../attendees/attendees_screen.dart';
import '../analytics/analytics_screen.dart';
import '../integrations/integrations_screen.dart';
import '../settings/settings_screen.dart';
import '../events/event_list_screen.dart';
import '../registration/ticket_types_screen.dart';
import '../registration/registration_form_screen.dart';
import '../operations/tasks_screen.dart';
import '../engagement/engagement_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  final _pages = const [
    CheckinScreen(),
    AttendeesScreen(),
    TasksScreen(),
    EngagementScreen(),
    IntegrationsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();

    await eventProvider.loadEvents(authProvider.organizationId);
    if (eventProvider.selectedEvent != null) {
      await context
          .read<AttendeeProvider>()
          .loadAttendees(eventProvider.selectedEvent!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Side navigation for larger screens
          if (MediaQuery.of(context).size.width >= 800) _buildSideNav(theme),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildAppBar(theme),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? _buildBottomNav(theme)
          : null,
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Event selector
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              return PopupMenuButton<String>(
                onSelected: (eventId) {
                  eventProvider.selectEvent(eventId);
                  context.read<AttendeeProvider>().loadAttendees(eventId);
                },
                itemBuilder: (context) {
                  return eventProvider.events.map((event) {
                    return PopupMenuItem(
                      value: event.id,
                      child: Row(
                        children: [
                          Icon(
                            event.isActive
                                ? Icons.event_available
                                : Icons.event,
                            color: event.isActive
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(event.name)),
                          if (event.id == eventProvider.selectedEvent?.id)
                            Icon(
                              Icons.check,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        eventProvider.selectedEvent?.name ?? 'Select Event',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          const SizedBox(width: 8),

          // Event Tools Menu
          Consumer<EventProvider>(
            builder: (context, provider, _) {
              final hasEvent = provider.selectedEvent != null;
              return PopupMenuButton<String>(
                enabled: true,
                tooltip: 'Event Tools',
                icon: const Icon(Icons.apps),
                onSelected: (value) {
                  if (value == 'manage_events') {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                              builder: (_) => const EventListScreen()),
                        )
                        .then((_) => _loadData());
                  } else if (value == 'tickets') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TicketTypesScreen()),
                    );
                  } else if (value == 'registration_form') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegistrationFormScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'manage_events',
                    child: Row(
                      children: [
                        Icon(Icons.list_alt),
                        SizedBox(width: 12),
                        Text('Manage Events'),
                      ],
                    ),
                  ),
                  if (hasEvent) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'tickets',
                      child: Row(
                        children: [
                          Icon(Icons.confirmation_number),
                          SizedBox(width: 12),
                          Text('Ticket Types'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'registration_form',
                      child: Row(
                        children: [
                          Icon(Icons.web),
                          SizedBox(width: 12),
                          Text('Registration Page'),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const Spacer(),
          // Sync status indicator
          Consumer<SyncProvider>(
            builder: (context, syncProvider, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: syncProvider.isOnline
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: syncProvider.isOnline
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      syncProvider.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: syncProvider.isOnline
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    if (syncProvider.hasPendingActions) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${syncProvider.pendingCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // User menu
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'signout') {
                    auth.signOut();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.displayName ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          auth.currentUser?.email ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 12),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    auth.currentUser?.displayName?.substring(0, 1) ?? 'U',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSideNav(ThemeData theme) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // Nav items
          _NavItem(
            icon: Icons.qr_code_scanner,
            label: 'Check-in',
            isSelected: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _NavItem(
            icon: Icons.people_outline,
            label: 'Attendees',
            isSelected: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _NavItem(
            icon: Icons.list_alt,
            label: 'Ops',
            isSelected: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _NavItem(
            icon: Icons.forum_outlined,
            label: 'Engage',
            isSelected: _selectedIndex == 3,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          _NavItem(
            icon: Icons.grid_view,
            label: 'Apps',
            isSelected: _selectedIndex == 4,
            onTap: () => setState(() => _selectedIndex = 4),
          ),
          _NavItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            isSelected: _selectedIndex == 5,
            onTap: () => setState(() => _selectedIndex = 5),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: _selectedIndex == 6,
            onTap: () => setState(() => _selectedIndex = 6),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: 'Check-in',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Attendees',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Ops',
        ),
        NavigationDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum),
          label: 'Engage',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Apps',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
