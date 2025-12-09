import 'package:flutter/foundation.dart';
import '../models/attendee.dart';
import '../services/firestore_service.dart';
import '../services/offline_sync_service.dart';

/// Attendee management provider
class AttendeeProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  OfflineSyncService? _offlineSyncService;

  List<Attendee> _attendees = [];
  List<Attendee> _searchResults = [];
  bool _isLoading = false;
  bool _useOfflineCache = false;
  String? _error;
  String _currentEventId = '';

  List<Attendee> get attendees => _attendees;
  List<Attendee> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get useOfflineCache => _useOfflineCache;
  String? get error => _error;

  // Stats
  int get totalCount => _attendees.length;
  int get checkedInCount => _attendees.where((a) => a.isCheckedIn).length;
  double get checkinPercentage =>
      totalCount > 0 ? (checkedInCount / totalCount) * 100 : 0;

  // Category breakdowns
  Map<String, int> get countByCategory {
    final map = <String, int>{};
    for (final a in _attendees) {
      map[a.category] = (map[a.category] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get checkedInByCategory {
    final map = <String, int>{};
    for (final a in _attendees.where((a) => a.isCheckedIn)) {
      map[a.category] = (map[a.category] ?? 0) + 1;
    }
    return map;
  }

  void setOfflineSyncService(OfflineSyncService service) {
    _offlineSyncService = service;
    service.onConnectivityChanged = (isOnline) {
      _useOfflineCache = !isOnline;
      notifyListeners();
    };
  }

  /// Load attendees for an event
  Future<void> loadAttendees(String eventId) async {
    _currentEventId = eventId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_offlineSyncService?.isOnline ?? true) {
        _attendees = await _firestoreService.getAttendees(eventId);
        // Cache for offline use
        _offlineSyncService?.cacheAttendees(eventId, _attendees);
        _useOfflineCache = false;
      } else {
        // Use cached data
        _attendees = _offlineSyncService?.getCachedAttendees(eventId) ?? [];
        _useOfflineCache = true;
      }
    } catch (e) {
      // Fallback to cache on error
      _attendees = _offlineSyncService?.getCachedAttendees(eventId) ?? [];
      _useOfflineCache = true;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search attendees
  Future<void> searchAttendees(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      if (_useOfflineCache) {
        _searchResults = _offlineSyncService?.searchCachedAttendees(
                _currentEventId, query) ??
            [];
      } else {
        _searchResults =
            await _firestoreService.searchAttendees(_currentEventId, query);
      }
    } catch (e) {
      _searchResults =
          _offlineSyncService?.searchCachedAttendees(_currentEventId, query) ??
              [];
    }
    notifyListeners();
  }

  /// Find attendee by QR code
  Future<Attendee?> findByQrCode(String qrCode) async {
    try {
      if (_useOfflineCache) {
        return _offlineSyncService?.findAttendeeByQrCode(
            _currentEventId, qrCode);
      }
      return await _firestoreService.getAttendeeByQrCode(
          _currentEventId, qrCode);
    } catch (e) {
      // Fallback
      return _offlineSyncService?.findAttendeeByQrCode(_currentEventId, qrCode);
    }
  }

  /// Add single attendee
  Future<void> addAttendee(Attendee attendee) async {
    try {
      final newAttendee = await _firestoreService.createAttendee(attendee);
      _attendees.add(newAttendee);
      // Update cache
      await _offlineSyncService?.updateCachedAttendee(
          _currentEventId, newAttendee);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Bulk create attendees
  Future<int> bulkCreateAttendees(List<Attendee> attendees) async {
    try {
      if (attendees.isEmpty) return 0;
      final count = await _firestoreService.bulkCreateAttendees(attendees);

      _attendees.addAll(attendees);

      // Update cache one by one or we'd need a bulk cache method
      // For now, just invalidate cache or add them
      for (final a in attendees) {
        await _offlineSyncService?.updateCachedAttendee(_currentEventId, a);
      }

      notifyListeners();
      return count;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update attendee (check-in, etc)
  Future<void> updateAttendee(Attendee attendee) async {
    try {
      // Update in local list
      final index = _attendees.indexWhere((a) => a.id == attendee.id);
      if (index >= 0) {
        _attendees[index] = attendee;
      }

      // Update cache
      await _offlineSyncService?.updateCachedAttendee(
          _currentEventId, attendee);

      // Sync to server if online
      if (_offlineSyncService?.isOnline ?? true) {
        await _firestoreService.updateAttendee(attendee);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh from server
  Future<void> refresh() async {
    await loadAttendees(_currentEventId);
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
