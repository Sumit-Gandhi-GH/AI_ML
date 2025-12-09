import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/attendee.dart';

/// Pending check-in action for offline queue
class PendingCheckin {
  final String id;
  final String attendeeId;
  final String eventId;
  final String action; // 'checkin', 'undo_checkin'
  final String method;
  final String performedBy;
  final String deviceId;
  final DateTime timestamp;
  final int retryCount;

  PendingCheckin({
    required this.id,
    required this.attendeeId,
    required this.eventId,
    required this.action,
    required this.method,
    required this.performedBy,
    required this.deviceId,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'attendeeId': attendeeId,
    'eventId': eventId,
    'action': action,
    'method': method,
    'performedBy': performedBy,
    'deviceId': deviceId,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory PendingCheckin.fromMap(Map<String, dynamic> map) {
    return PendingCheckin(
      id: map['id'],
      attendeeId: map['attendeeId'],
      eventId: map['eventId'],
      action: map['action'],
      method: map['method'],
      performedBy: map['performedBy'],
      deviceId: map['deviceId'],
      timestamp: DateTime.parse(map['timestamp']),
      retryCount: map['retryCount'] ?? 0,
    );
  }

  PendingCheckin incrementRetry() {
    return PendingCheckin(
      id: id,
      attendeeId: attendeeId,
      eventId: eventId,
      action: action,
      method: method,
      performedBy: performedBy,
      deviceId: deviceId,
      timestamp: timestamp,
      retryCount: retryCount + 1,
    );
  }
}

/// Offline sync service for managing local cache and sync queue
class OfflineSyncService {
  static const String _attendeesBoxName = 'attendees';
  static const String _pendingCheckinBoxName = 'pendingCheckins';
  static const String _syncMetaBoxName = 'syncMeta';

  late Box<String> _attendeesBox;
  late Box<String> _pendingCheckinBox;
  late Box<dynamic> _syncMetaBox;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;

  // Callbacks for sync events
  Function(bool)? onConnectivityChanged;
  Function(PendingCheckin)? onCheckinSynced;
  Function(String)? onSyncError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  /// Initialize Hive boxes
  Future<void> initialize() async {
    _attendeesBox = await Hive.openBox<String>(_attendeesBoxName);
    _pendingCheckinBox = await Hive.openBox<String>(_pendingCheckinBoxName);
    _syncMetaBox = await Hive.openBox(_syncMetaBoxName);

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final wasOffline = !_isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);
        
        onConnectivityChanged?.call(_isOnline);
        
        // Auto-sync when coming back online
        if (wasOffline && _isOnline) {
          syncPendingCheckins();
        }
      },
    );
  }

  /// Cache attendees for offline access
  Future<void> cacheAttendees(String eventId, List<Attendee> attendees) async {
    final eventKey = 'event_$eventId';
    final attendeesJson = jsonEncode(
      attendees.map((a) => a.toMap()).toList(),
    );
    await _attendeesBox.put(eventKey, attendeesJson);
    await _syncMetaBox.put('${eventKey}_lastSync', DateTime.now().toIso8601String());
  }

  /// Get cached attendees for an event
  List<Attendee> getCachedAttendees(String eventId) {
    final eventKey = 'event_$eventId';
    final json = _attendeesBox.get(eventKey);
    if (json == null) return [];

    final List<dynamic> data = jsonDecode(json);
    return data
        .map((m) => Attendee.fromMap(Map<String, dynamic>.from(m), m['id']))
        .toList();
  }

  /// Search cached attendees
  List<Attendee> searchCachedAttendees(String eventId, String query) {
    final attendees = getCachedAttendees(eventId);
    final lowerQuery = query.toLowerCase();
    
    return attendees.where((a) {
      return a.fullName.toLowerCase().contains(lowerQuery) ||
             a.email.toLowerCase().contains(lowerQuery) ||
             (a.company?.toLowerCase().contains(lowerQuery) ?? false) ||
             a.qrCode.toLowerCase() == lowerQuery;
    }).toList();
  }

  /// Find attendee by QR code (optimized for speed)
  Attendee? findAttendeeByQrCode(String eventId, String qrCode) {
    final attendees = getCachedAttendees(eventId);
    try {
      return attendees.firstWhere((a) => a.qrCode == qrCode);
    } catch (e) {
      return null;
    }
  }

  /// Update cached attendee
  Future<void> updateCachedAttendee(String eventId, Attendee attendee) async {
    final attendees = getCachedAttendees(eventId);
    final index = attendees.indexWhere((a) => a.id == attendee.id);
    
    if (index >= 0) {
      attendees[index] = attendee;
    } else {
      attendees.add(attendee);
    }
    
    await cacheAttendees(eventId, attendees);
  }

  /// Queue a check-in action for offline processing
  Future<void> queueCheckin(PendingCheckin checkin) async {
    await _pendingCheckinBox.put(checkin.id, jsonEncode(checkin.toMap()));
  }

  /// Get all pending check-ins
  List<PendingCheckin> getPendingCheckins() {
    return _pendingCheckinBox.values
        .map((json) => PendingCheckin.fromMap(jsonDecode(json)))
        .toList();
  }

  /// Get pending check-in count
  int get pendingCheckinCount => _pendingCheckinBox.length;

  /// Sync pending check-ins to server
  Future<void> syncPendingCheckins() async {
    if (_isSyncing || !_isOnline) return;
    _isSyncing = true;

    final pending = getPendingCheckins();
    
    for (final checkin in pending) {
      try {
        // TODO: Call Firestore service to sync
        // await _firestoreService.syncCheckin(checkin);
        
        // Remove from queue after successful sync
        await _pendingCheckinBox.delete(checkin.id);
        onCheckinSynced?.call(checkin);
      } catch (e) {
        // Increment retry count
        final updated = checkin.incrementRetry();
        if (updated.retryCount < 5) {
          await _pendingCheckinBox.put(checkin.id, jsonEncode(updated.toMap()));
        } else {
          // Max retries reached, log error
          onSyncError?.call('Failed to sync check-in for ${checkin.attendeeId}');
          await _pendingCheckinBox.delete(checkin.id);
        }
      }
    }

    _isSyncing = false;
  }

  /// Clear all cached data for an event
  Future<void> clearEventCache(String eventId) async {
    await _attendeesBox.delete('event_$eventId');
  }

  /// Get last sync time for an event
  DateTime? getLastSyncTime(String eventId) {
    final timestamp = _syncMetaBox.get('event_${eventId}_lastSync');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
