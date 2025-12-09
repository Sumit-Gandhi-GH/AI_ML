/// Organization model - top-level entity for multi-tenancy
class Organization {
  final String id;
  final String name;
  final String? logoUrl;
  final String ownerEmail;
  final String ownerId;
  final OrganizationPlan plan;
  final int eventsUsed;
  final int eventsLimit;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.ownerEmail,
    required this.ownerId,
    this.plan = OrganizationPlan.free,
    this.eventsUsed = 0,
    this.eventsLimit = 100,
    this.memberIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if organization has reached event limit
  bool get hasReachedLimit => eventsUsed >= eventsLimit;

  /// Remaining events in plan
  int get eventsRemaining => eventsLimit - eventsUsed;

  /// Usage percentage
  double get usagePercentage => (eventsUsed / eventsLimit) * 100;

  /// Check if organization is on free plan
  bool get isFreePlan => plan == OrganizationPlan.free;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'ownerEmail': ownerEmail,
    'ownerId': ownerId,
    'plan': plan.name,
    'eventsUsed': eventsUsed,
    'eventsLimit': eventsLimit,
    'memberIds': memberIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Organization.fromMap(Map<String, dynamic> map, String docId) {
    return Organization(
      id: docId,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
      ownerEmail: map['ownerEmail'] ?? '',
      ownerId: map['ownerId'] ?? '',
      plan: OrganizationPlan.values.firstWhere(
        (p) => p.name == map['plan'],
        orElse: () => OrganizationPlan.free,
      ),
      eventsUsed: map['eventsUsed'] ?? 0,
      eventsLimit: map['eventsLimit'] ?? 100,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Organization copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? ownerEmail,
    String? ownerId,
    OrganizationPlan? plan,
    int? eventsUsed,
    int? eventsLimit,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerId: ownerId ?? this.ownerId,
      plan: plan ?? this.plan,
      eventsUsed: eventsUsed ?? this.eventsUsed,
      eventsLimit: eventsLimit ?? this.eventsLimit,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Organization plan types
enum OrganizationPlan {
  free,       // 100 free events
  starter,    // Paid tier 1
  professional, // Paid tier 2
  enterprise,  // Paid tier 3
}

/// Plan feature limits
class PlanLimits {
  final int maxEvents;
  final int maxAttendeesPerEvent;
  final int maxDevicesPerEvent;
  final bool customBranding;
  final bool apiAccess;
  final bool prioritySupport;

  const PlanLimits({
    required this.maxEvents,
    required this.maxAttendeesPerEvent,
    required this.maxDevicesPerEvent,
    this.customBranding = false,
    this.apiAccess = false,
    this.prioritySupport = false,
  });

  static PlanLimits forPlan(OrganizationPlan plan) {
    switch (plan) {
      case OrganizationPlan.free:
        return const PlanLimits(
          maxEvents: 100,
          maxAttendeesPerEvent: 500,
          maxDevicesPerEvent: 5,
        );
      case OrganizationPlan.starter:
        return const PlanLimits(
          maxEvents: -1, // unlimited
          maxAttendeesPerEvent: 1000,
          maxDevicesPerEvent: 10,
          customBranding: true,
        );
      case OrganizationPlan.professional:
        return const PlanLimits(
          maxEvents: -1,
          maxAttendeesPerEvent: 5000,
          maxDevicesPerEvent: 25,
          customBranding: true,
          apiAccess: true,
        );
      case OrganizationPlan.enterprise:
        return const PlanLimits(
          maxEvents: -1,
          maxAttendeesPerEvent: -1,
          maxDevicesPerEvent: -1,
          customBranding: true,
          apiAccess: true,
          prioritySupport: true,
        );
    }
  }
}
