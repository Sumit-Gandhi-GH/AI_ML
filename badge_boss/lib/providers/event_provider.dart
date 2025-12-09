import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';

/// Event management provider
class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelectedEvent => _selectedEvent != null;

  // Filter events by status
  List<Event> get activeEvents => _events.where((e) => e.isActive).toList();
  List<Event> get upcomingEvents => _events.where((e) => e.isUpcoming).toList();
  List<Event> get pastEvents => _events.where((e) => e.hasEnded).toList();

  /// Load events for organization
  Future<void> loadEvents(String organizationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _firestoreService.getEvents(organizationId);

      // Auto-select the first active event
      if (_selectedEvent == null && _events.isNotEmpty) {
        final active =
            activeEvents.isNotEmpty ? activeEvents.first : _events.first;
        await selectEvent(active.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an event for check-in
  Future<void> selectEvent(String eventId) async {
    _selectedEvent = await _firestoreService.getEvent(eventId);
    notifyListeners();
  }

  /// Create a new event
  Future<Event?> createEvent(Event event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _firestoreService.createEvent(event);
      _events.add(created);
      return created;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update event settings
  Future<void> updateEvent(Event event) async {
    try {
      final updated = await _firestoreService.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index >= 0) {
        _events[index] = updated;
      }
      if (_selectedEvent?.id == event.id) {
        _selectedEvent = updated;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh selected event stats
  Future<void> refreshEventStats() async {
    if (_selectedEvent == null) return;

    try {
      _selectedEvent = await _firestoreService.getEvent(_selectedEvent!.id);
      notifyListeners();
    } catch (e) {
      // Silent fail for stats refresh
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestoreService.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      if (_selectedEvent?.id == eventId) {
        _selectedEvent = _events.isNotEmpty ? _events.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
