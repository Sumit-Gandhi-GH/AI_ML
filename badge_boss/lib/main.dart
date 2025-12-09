import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/attendee_provider.dart';
import 'providers/checkin_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/registration_provider.dart';
import 'providers/operations_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/integrations_provider.dart';
import 'providers/analytics_provider.dart';
import 'services/offline_sync_service.dart';

/// Badge Boss - Professional Event Check-in & Badging Solution
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize offline sync service
  final offlineSyncService = OfflineSyncService();
  await offlineSyncService.initialize();

  debugPrint('Badge Boss starting in demo mode...');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              AttendeeProvider()..setOfflineSyncService(offlineSyncService),
        ),
        ChangeNotifierProvider(
          create: (_) => CheckinProvider(offlineSyncService),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(offlineSyncService),
        ),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => OperationsProvider()),
        ChangeNotifierProvider(create: (_) => EngagementProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => IntegrationsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: const BadgeBossApp(),
    ),
  );
}
