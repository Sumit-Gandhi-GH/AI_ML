/// Event model for Badge Boss
class Event {
  final String id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? venue;
  final String? venueAddress;
  final String? logoUrl;
  final String organizationId;
  final EventSettings settings;
  final EventStats stats;
  final String? badgeTemplateId;
  final List<String> categories;
  final List<CustomFieldDefinition> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Event({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.venue,
    this.venueAddress,
    this.logoUrl,
    required this.organizationId,
    EventSettings? settings,
    EventStats? stats,
    this.badgeTemplateId,
    this.categories = const ['general', 'vip', 'speaker', 'sponsor', 'staff'],
    this.customFields = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  })  : settings = settings ?? EventSettings(),
        stats = stats ?? EventStats();

  /// Check if event is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if event is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// Check if event has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  /// Check-in percentage
  double get checkinPercentage {
    if (stats.totalRegistered == 0) return 0;
    return (stats.totalCheckedIn / stats.totalRegistered) * 100;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'venue': venue,
        'venueAddress': venueAddress,
        'logoUrl': logoUrl,
        'organizationId': organizationId,
        'settings': settings.toMap(),
        'stats': stats.toMap(),
        'badgeTemplateId': badgeTemplateId,
        'categories': categories,
        'customFields': customFields.map((f) => f.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory Event.fromMap(Map<String, dynamic> map, String docId) {
    return Event(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      venue: map['venue'],
      venueAddress: map['venueAddress'],
      logoUrl: map['logoUrl'],
      organizationId: map['organizationId'] ?? '',
      settings: EventSettings.fromMap(map['settings']),
      stats: EventStats.fromMap(map['stats']),
      badgeTemplateId: map['badgeTemplateId'],
      categories: List<String>.from(map['categories'] ?? []),
      customFields: (map['customFields'] as List?)
              ?.map((f) => CustomFieldDefinition.fromMap(f))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Event copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? venue,
    String? venueAddress,
    String? logoUrl,
    String? organizationId,
    EventSettings? settings,
    EventStats? stats,
    String? badgeTemplateId,
    List<String>? categories,
    List<CustomFieldDefinition>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      organizationId: organizationId ?? this.organizationId,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      badgeTemplateId: badgeTemplateId ?? this.badgeTemplateId,
      categories: categories ?? this.categories,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Event settings
class EventSettings {
  final bool enableKioskMode;
  final bool autoPrintOnCheckin;
  final bool allowDuplicateScans;
  final bool requirePhotoVerification;
  final bool enableOfflineMode;
  final bool enableSessionTracking;
  final int scanCooldownSeconds;
  final int maxCapacity;

  // Alias getters for compatibility
  bool get allowDuplicateCheckin => allowDuplicateScans;
  bool get printBadgeOnCheckin => autoPrintOnCheckin;

  EventSettings({
    this.enableKioskMode = false,
    this.autoPrintOnCheckin = true,
    this.allowDuplicateScans = false,
    this.requirePhotoVerification = false,
    this.enableOfflineMode = true,
    this.enableSessionTracking = false,
    this.scanCooldownSeconds = 0,
    this.maxCapacity = 0,
  });

  Map<String, dynamic> toMap() => {
        'enableKioskMode': enableKioskMode,
        'autoPrintOnCheckin': autoPrintOnCheckin,
        'allowDuplicateScans': allowDuplicateScans,
        'requirePhotoVerification': requirePhotoVerification,
        'enableOfflineMode': enableOfflineMode,
        'enableSessionTracking': enableSessionTracking,
        'scanCooldownSeconds': scanCooldownSeconds,
        'maxCapacity': maxCapacity,
      };

  factory EventSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return EventSettings();
    return EventSettings(
      enableKioskMode: map['enableKioskMode'] ?? false,
      autoPrintOnCheckin: map['autoPrintOnCheckin'] ?? true,
      allowDuplicateScans: map['allowDuplicateScans'] ?? false,
      requirePhotoVerification: map['requirePhotoVerification'] ?? false,
      enableOfflineMode: map['enableOfflineMode'] ?? true,
      enableSessionTracking: map['enableSessionTracking'] ?? false,
      scanCooldownSeconds: map['scanCooldownSeconds'] ?? 0,
      maxCapacity: map['maxCapacity'] ?? 0,
    );
  }

  EventSettings copyWith({
    bool? enableKioskMode,
    bool? autoPrintOnCheckin,
    bool? allowDuplicateScans,
    bool? requirePhotoVerification,
    bool? enableOfflineMode,
    bool? enableSessionTracking,
    int? scanCooldownSeconds,
    int? maxCapacity,
  }) {
    return EventSettings(
      enableKioskMode: enableKioskMode ?? this.enableKioskMode,
      autoPrintOnCheckin: autoPrintOnCheckin ?? this.autoPrintOnCheckin,
      allowDuplicateScans: allowDuplicateScans ?? this.allowDuplicateScans,
      requirePhotoVerification:
          requirePhotoVerification ?? this.requirePhotoVerification,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      enableSessionTracking:
          enableSessionTracking ?? this.enableSessionTracking,
      scanCooldownSeconds: scanCooldownSeconds ?? this.scanCooldownSeconds,
      maxCapacity: maxCapacity ?? this.maxCapacity,
    );
  }
}

/// Real-time event statistics
class EventStats {
  final int totalRegistered;
  final int totalCheckedIn;
  final Map<String, int> checkinsByCategory;
  final Map<String, int> checkinsByHour;

  // Alias getter for compatibility
  int get checkedIn => totalCheckedIn;

  EventStats({
    this.totalRegistered = 0,
    this.totalCheckedIn = 0,
    this.checkinsByCategory = const {},
    this.checkinsByHour = const {},
  });

  Map<String, dynamic> toMap() => {
        'totalRegistered': totalRegistered,
        'totalCheckedIn': totalCheckedIn,
        'checkinsByCategory': checkinsByCategory,
        'checkinsByHour': checkinsByHour,
      };

  factory EventStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return EventStats();
    return EventStats(
      totalRegistered: map['totalRegistered'] ?? 0,
      totalCheckedIn: map['totalCheckedIn'] ?? 0,
      checkinsByCategory:
          Map<String, int>.from(map['checkinsByCategory'] ?? {}),
      checkinsByHour: Map<String, int>.from(map['checkinsByHour'] ?? {}),
    );
  }

  EventStats copyWith({
    int? totalRegistered,
    int? totalCheckedIn,
    Map<String, int>? checkinsByCategory,
    Map<String, int>? checkinsByHour,
  }) {
    return EventStats(
      totalRegistered: totalRegistered ?? this.totalRegistered,
      totalCheckedIn: totalCheckedIn ?? this.totalCheckedIn,
      checkinsByCategory: checkinsByCategory ?? this.checkinsByCategory,
      checkinsByHour: checkinsByHour ?? this.checkinsByHour,
    );
  }
}

/// Custom field definition
class CustomFieldDefinition {
  final String key;
  final String label;
  final String type; // 'text', 'select', 'checkbox', 'date'
  final List<String>? options;
  final bool isRequired;
  final bool showOnBadge;

  CustomFieldDefinition({
    required this.key,
    required this.label,
    this.type = 'text',
    this.options,
    this.isRequired = false,
    this.showOnBadge = false,
  });

  Map<String, dynamic> toMap() => {
        'key': key,
        'label': label,
        'type': type,
        'options': options,
        'isRequired': isRequired,
        'showOnBadge': showOnBadge,
      };

  factory CustomFieldDefinition.fromMap(Map<String, dynamic> map) {
    return CustomFieldDefinition(
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      options:
          map['options'] != null ? List<String>.from(map['options']) : null,
      isRequired: map['isRequired'] ?? false,
      showOnBadge: map['showOnBadge'] ?? false,
    );
  }
}
