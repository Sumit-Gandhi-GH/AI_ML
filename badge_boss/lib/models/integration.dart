enum IntegrationCategory { payment, crm, marketing, communication, analytics }

enum IntegrationStatus { disconnected, connected, error }

class Integration {
  final String id;
  final String name;
  final String description;
  final String iconAsset; // Or use IconData for demo
  final IntegrationCategory category;
  final IntegrationStatus status;
  final DateTime? connectedAt;
  final Map<String, dynamic> config;

  Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.category,
    this.status = IntegrationStatus.disconnected,
    this.connectedAt,
    this.config = const {},
  });

  Integration copyWith({
    IntegrationStatus? status,
    DateTime? connectedAt,
    Map<String, dynamic>? config,
  }) {
    return Integration(
      id: id,
      name: name,
      description: description,
      iconAsset: iconAsset,
      category: category,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      config: config ?? this.config,
    );
  }
}
