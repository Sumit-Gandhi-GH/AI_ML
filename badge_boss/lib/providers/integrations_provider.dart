import 'package:flutter/foundation.dart';
import '../models/integration.dart';

class IntegrationsProvider with ChangeNotifier {
  List<Integration> _integrations = [
    Integration(
      id: 'stripe',
      name: 'Stripe',
      description: 'Accept payments for ticket sales securely.',
      iconAsset: 'assets/icons/stripe.png', // Placeholder
      category: IntegrationCategory.payment,
      status: IntegrationStatus.connected,
      connectedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Integration(
      id: 'paypal',
      name: 'PayPal',
      description: 'Alternative payment provider for global reach.',
      iconAsset: 'assets/icons/paypal.png',
      category: IntegrationCategory.payment,
    ),
    Integration(
      id: 'salesforce',
      name: 'Salesforce',
      description: 'Sync attendee data with your CRM.',
      iconAsset: 'assets/icons/salesforce.png',
      category: IntegrationCategory.crm,
    ),
    Integration(
      id: 'mailchimp',
      name: 'Mailchimp',
      description: 'Send automated email campaigns to attendees.',
      iconAsset: 'assets/icons/mailchimp.png',
      category: IntegrationCategory.marketing,
    ),
    Integration(
      id: 'slack',
      name: 'Slack',
      description: 'Get real-time notifications for check-ins and alerts.',
      iconAsset: 'assets/icons/slack.png',
      category: IntegrationCategory.communication,
    ),
  ];

  List<Integration> get integrations => _integrations;

  List<Integration> getConnectedIntegrations() {
    return _integrations
        .where((i) => i.status == IntegrationStatus.connected)
        .toList();
  }

  final Set<String> _loadingIds = {};

  bool isIntegrationLoading(String id) => _loadingIds.contains(id);

  Future<void> toggleConnection(String id) async {
    if (_loadingIds.contains(id)) return;

    _loadingIds.add(id);
    notifyListeners();

    final index = _integrations.indexWhere((i) => i.id == id);
    if (index != -1) {
      final integration = _integrations[index];
      final newStatus = integration.status == IntegrationStatus.connected
          ? IntegrationStatus.disconnected
          : IntegrationStatus.connected;

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _integrations[index] = integration.copyWith(
        status: newStatus,
        connectedAt:
            newStatus == IntegrationStatus.connected ? DateTime.now() : null,
      );
    }

    _loadingIds.remove(id);
    notifyListeners();
  }
}
