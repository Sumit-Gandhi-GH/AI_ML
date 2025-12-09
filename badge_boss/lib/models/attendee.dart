/// Attendee data models for Badge Boss

/// Represents the check-in status of an attendee
class CheckinStatus {
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final String? checkInMethod; // 'qr', 'nfc', 'manual', 'kiosk'
  final String? checkedInBy;
  final String? deviceId;

  CheckinStatus({
    this.isCheckedIn = false,
    this.checkedInAt,
    this.checkInMethod,
    this.checkedInBy,
    this.deviceId,
  });

  Map<String, dynamic> toMap() => {
    'isCheckedIn': isCheckedIn,
    'checkedInAt': checkedInAt?.toIso8601String(),
    'checkInMethod': checkInMethod,
    'checkedInBy': checkedInBy,
    'deviceId': deviceId,
  };

  factory CheckinStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CheckinStatus();
    return CheckinStatus(
      isCheckedIn: map['isCheckedIn'] ?? false,
      checkedInAt: map['checkedInAt'] != null 
          ? DateTime.parse(map['checkedInAt']) 
          : null,
      checkInMethod: map['checkInMethod'],
      checkedInBy: map['checkedInBy'],
      deviceId: map['deviceId'],
    );
  }

  CheckinStatus copyWith({
    bool? isCheckedIn,
    DateTime? checkedInAt,
    String? checkInMethod,
    String? checkedInBy,
    String? deviceId,
  }) {
    return CheckinStatus(
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

/// Represents the badge printing status
class BadgeStatus {
  final bool isPrinted;
  final int printCount;
  final DateTime? printedAt;

  BadgeStatus({
    this.isPrinted = false,
    this.printCount = 0,
    this.printedAt,
  });

  Map<String, dynamic> toMap() => {
    'isPrinted': isPrinted,
    'printCount': printCount,
    'printedAt': printedAt?.toIso8601String(),
  };

  factory BadgeStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return BadgeStatus();
    return BadgeStatus(
      isPrinted: map['isPrinted'] ?? false,
      printCount: map['printCount'] ?? 0,
      printedAt: map['printedAt'] != null 
          ? DateTime.parse(map['printedAt']) 
          : null,
    );
  }

  BadgeStatus copyWith({
    bool? isPrinted,
    int? printCount,
    DateTime? printedAt,
  }) {
    return BadgeStatus(
      isPrinted: isPrinted ?? this.isPrinted,
      printCount: printCount ?? this.printCount,
      printedAt: printedAt ?? this.printedAt,
    );
  }
}

/// Attendee categories
enum AttendeeCategory {
  general,
  vip,
  speaker,
  sponsor,
  staff,
  media,
  exhibitor,
}

/// Registration source
enum RegistrationSource {
  import,    // CSV/Excel import
  manual,    // Added manually in-app
  walkIn,    // Walk-in registration at event
  api,       // External API
}

/// Main Attendee model
class Attendee {
  final String id;

  final String firstName;

  final String lastName;

  final String email;

  final String? company;

  final String? title;

  final String? phone;

  final String category;

  final String qrCode;

  final String? photoUrl;

  final Map<String, dynamic> customFields;

  final Map<String, dynamic> checkinStatusMap;

  final Map<String, dynamic> badgeStatusMap;

  final String registrationSource;

  final DateTime createdAt;

  final DateTime updatedAt;

  final String eventId;

  final String organizationId;

  Attendee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.company,
    this.title,
    this.phone,
    this.category = 'general',
    required this.qrCode,
    this.photoUrl,
    this.customFields = const {},
    this.checkinStatusMap = const {},
    this.badgeStatusMap = const {},
    this.registrationSource = 'import',
    required this.createdAt,
    required this.updatedAt,
    required this.eventId,
    required this.organizationId,
  });

  /// Full name helper
  String get fullName => '$firstName $lastName'.trim();

  /// Get typed check-in status
  CheckinStatus get checkinStatus => CheckinStatus.fromMap(checkinStatusMap);

  /// Get typed badge status
  BadgeStatus get badgeStatus => BadgeStatus.fromMap(badgeStatusMap);

  /// Check if checked in
  bool get isCheckedIn => checkinStatus.isCheckedIn;

  /// Get category enum
  AttendeeCategory get categoryEnum {
    return AttendeeCategory.values.firstWhere(
      (c) => c.name == category,
      orElse: () => AttendeeCategory.general,
    );
  }

  /// Get registration source enum
  RegistrationSource get registrationSourceEnum {
    return RegistrationSource.values.firstWhere(
      (s) => s.name == registrationSource,
      orElse: () => RegistrationSource.import,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'company': company,
    'title': title,
    'phone': phone,
    'category': category,
    'qrCode': qrCode,
    'photoUrl': photoUrl,
    'customFields': customFields,
    'checkinStatus': checkinStatusMap,
    'badgeStatus': badgeStatusMap,
    'registrationSource': registrationSource,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'eventId': eventId,
    'organizationId': organizationId,
  };

  /// Create from Firestore map
  factory Attendee.fromMap(Map<String, dynamic> map, String docId) {
    return Attendee(
      id: docId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      company: map['company'],
      title: map['title'],
      phone: map['phone'],
      category: map['category'] ?? 'general',
      qrCode: map['qrCode'] ?? '',
      photoUrl: map['photoUrl'],
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      checkinStatusMap: Map<String, dynamic>.from(map['checkinStatus'] ?? {}),
      badgeStatusMap: Map<String, dynamic>.from(map['badgeStatus'] ?? {}),
      registrationSource: map['registrationSource'] ?? 'import',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      eventId: map['eventId'] ?? '',
      organizationId: map['organizationId'] ?? '',
    );
  }

  /// Copy with method for immutable updates
  Attendee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? company,
    String? title,
    String? phone,
    String? category,
    String? qrCode,
    String? photoUrl,
    Map<String, dynamic>? customFields,
    Map<String, dynamic>? checkinStatusMap,
    Map<String, dynamic>? badgeStatusMap,
    String? registrationSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? eventId,
    String? organizationId,
  }) {
    return Attendee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      company: company ?? this.company,
      title: title ?? this.title,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      qrCode: qrCode ?? this.qrCode,
      photoUrl: photoUrl ?? this.photoUrl,
      customFields: customFields ?? this.customFields,
      checkinStatusMap: checkinStatusMap ?? this.checkinStatusMap,
      badgeStatusMap: badgeStatusMap ?? this.badgeStatusMap,
      registrationSource: registrationSource ?? this.registrationSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eventId: eventId ?? this.eventId,
      organizationId: organizationId ?? this.organizationId,
    );
  }

  /// Update check-in status
  Attendee checkIn({
    required String method,
    required String checkedInBy,
    required String deviceId,
  }) {
    final status = CheckinStatus(
      isCheckedIn: true,
      checkedInAt: DateTime.now(),
      checkInMethod: method,
      checkedInBy: checkedInBy,
      deviceId: deviceId,
    );
    return copyWith(
      checkinStatusMap: status.toMap(),
      updatedAt: DateTime.now(),
    );
  }

  /// Undo check-in
  Attendee undoCheckIn() {
    return copyWith(
      checkinStatusMap: CheckinStatus().toMap(),
      updatedAt: DateTime.now(),
    );
  }

  /// Mark badge as printed
  Attendee markBadgePrinted() {
    final currentStatus = badgeStatus;
    final newStatus = BadgeStatus(
      isPrinted: true,
      printCount: currentStatus.printCount + 1,
      printedAt: DateTime.now(),
    );
    return copyWith(
      badgeStatusMap: newStatus.toMap(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'Attendee($fullName, $email)';
}
