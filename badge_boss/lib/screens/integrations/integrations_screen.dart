import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/integration.dart';
import '../../providers/integrations_provider.dart';

class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IntegrationsProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Integrations Marketplace'),
            Text(
              'Demo Environment - Connections are simulated',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Connect your favorite tools to supercharge your event operations.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final integration = provider.integrations[index];
                  return _IntegrationCard(integration: integration);
                },
                childCount: provider.integrations.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final Integration integration;

  const _IntegrationCard({required this.integration});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = integration.status == IntegrationStatus.connected;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconPlaceholder(integration.name),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            integration.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              integration.category.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    integration.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Provider.of<IntegrationsProvider>(context)
                          .isIntegrationLoading(integration.id)
                      ? const Center(
                          child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : isConnected
                          ? OutlinedButton.icon(
                              onPressed: () => _toggleConnection(context),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Connected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _toggleConnection(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: const Text('Connect'),
                            ),
                ),
              ],
            ),
          ),
          if (isConnected)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(12)),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleConnection(BuildContext context) {
    context.read<IntegrationsProvider>().toggleConnection(integration.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          integration.status == IntegrationStatus.connected
              ? 'Disconnecting ${integration.name}...'
              : 'Connecting to ${integration.name}...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildIconPlaceholder(String name) {
    // Determine color based on integration name hash
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple
    ];
    final color = colors[name.hashCode % colors.length];

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        name[0],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
