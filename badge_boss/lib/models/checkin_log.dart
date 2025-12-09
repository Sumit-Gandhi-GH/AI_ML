/// Check-in log for audit trail
class CheckinLog {
  final String id;
  final String attendeeId;
  final String eventId;
  final String organizationId;
  final String action; // 'checkin', 'undo_checkin', 'reprint'
  final String method; // 'qr', 'nfc', 'manual', 'kiosk'
  final String performedBy;
  final String deviceId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  CheckinLog({
    required this.id,
    required this.attendeeId,
    required this.eventId,
    required this.organizationId,
    required this.action,
    required this.method,
    required this.performedBy,
    required this.deviceId,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'attendeeId': attendeeId,
    'eventId': eventId,
    'organizationId': organizationId,
    'action': action,
    'method': method,
    'performedBy': performedBy,
    'deviceId': deviceId,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory CheckinLog.fromMap(Map<String, dynamic> map, String docId) {
    return CheckinLog(
      id: docId,
      attendeeId: map['attendeeId'] ?? '',
      eventId: map['eventId'] ?? '',
      organizationId: map['organizationId'] ?? '',
      action: map['action'] ?? '',
      method: map['method'] ?? '',
      performedBy: map['performedBy'] ?? '',
      deviceId: map['deviceId'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }
}

/// Session for breakout/workshop tracking
class Session {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final int checkedInCount;
  final List<String> speakerIds;
  final String? category;

  Session({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.capacity = 0,
    this.checkedInCount = 0,
    this.speakerIds = const [],
    this.category,
  });

  bool get isAtCapacity => capacity > 0 && checkedInCount >= capacity;
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventId': eventId,
    'name': name,
    'description': description,
    'location': location,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'capacity': capacity,
    'checkedInCount': checkedInCount,
    'speakerIds': speakerIds,
    'category': category,
  };

  factory Session.fromMap(Map<String, dynamic> map, String docId) {
    return Session(
      id: docId,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      location: map['location'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      capacity: map['capacity'] ?? 0,
      checkedInCount: map['checkedInCount'] ?? 0,
      speakerIds: List<String>.from(map['speakerIds'] ?? []),
      category: map['category'],
    );
  }
}

/// Device registration for check-in stations
class Device {
  final String id;
  final String eventId;
  final String name;
  final String deviceType; // 'phone', 'tablet', 'kiosk'
  final String platform; // 'ios', 'android'
  final String? assignedTo;
  final bool isKioskMode;
  final String? connectedPrinterId;
  final DateTime lastActiveAt;
  final DeviceStatus status;

  Device({
    required this.id,
    required this.eventId,
    required this.name,
    required this.deviceType,
    required this.platform,
    this.assignedTo,
    this.isKioskMode = false,
    this.connectedPrinterId,
    required this.lastActiveAt,
    this.status = DeviceStatus.active,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventId': eventId,
    'name': name,
    'deviceType': deviceType,
    'platform': platform,
    'assignedTo': assignedTo,
    'isKioskMode': isKioskMode,
    'connectedPrinterId': connectedPrinterId,
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'status': status.name,
  };

  factory Device.fromMap(Map<String, dynamic> map, String docId) {
    return Device(
      id: docId,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      deviceType: map['deviceType'] ?? 'phone',
      platform: map['platform'] ?? 'android',
      assignedTo: map['assignedTo'],
      isKioskMode: map['isKioskMode'] ?? false,
      connectedPrinterId: map['connectedPrinterId'],
      lastActiveAt: DateTime.parse(map['lastActiveAt']),
      status: DeviceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DeviceStatus.active,
      ),
    );
  }
}

enum DeviceStatus {
  active,
  inactive,
  maintenance,
}

/// Printer configuration
class PrinterConfig {
  final String id;
  final String eventId;
  final String name;
  final String model; // 'zebra_zd420', 'brother_ql820', etc.
  final String connectionType; // 'bluetooth', 'wifi', 'usb'
  final String? macAddress;
  final String? ipAddress;
  final PrinterStatus status;
  final DateTime lastUsedAt;

  PrinterConfig({
    required this.id,
    required this.eventId,
    required this.name,
    required this.model,
    required this.connectionType,
    this.macAddress,
    this.ipAddress,
    this.status = PrinterStatus.ready,
    required this.lastUsedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventId': eventId,
    'name': name,
    'model': model,
    'connectionType': connectionType,
    'macAddress': macAddress,
    'ipAddress': ipAddress,
    'status': status.name,
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  factory PrinterConfig.fromMap(Map<String, dynamic> map, String docId) {
    return PrinterConfig(
      id: docId,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      model: map['model'] ?? '',
      connectionType: map['connectionType'] ?? 'bluetooth',
      macAddress: map['macAddress'],
      ipAddress: map['ipAddress'],
      status: PrinterStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PrinterStatus.ready,
      ),
      lastUsedAt: DateTime.parse(map['lastUsedAt']),
    );
  }
}

enum PrinterStatus {
  ready,
  printing,
  offline,
  error,
  paperOut,
}
