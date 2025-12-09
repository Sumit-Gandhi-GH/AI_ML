import 'package:flutter/foundation.dart';
import '../models/registration.dart';
import '../services/firestore_service.dart';

/// Registration management provider
class RegistrationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<TicketType> _ticketTypes = [];
  List<Registration> _registrations = [];
  List<PromoCode> _promoCodes = [];
  bool _isLoading = false;
  String? _error;

  List<TicketType> get ticketTypes => _ticketTypes;
  List<Registration> get registrations => _registrations;
  List<PromoCode> get promoCodes => _promoCodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<TicketType> get activeTickets =>
      _ticketTypes.where((t) => t.isActive).toList();
  List<Registration> get confirmedRegistrations => _registrations
      .where((r) => r.status == RegistrationStatus.confirmed)
      .toList();
  List<Registration> get pendingRegistrations => _registrations
      .where((r) => r.status == RegistrationStatus.pending)
      .toList();

  // ==================== Ticket Types ====================

  Future<void> loadTicketTypes(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ticketTypes = await _firestoreService.getTicketTypes(eventId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketType?> createTicketType(TicketType ticket) async {
    try {
      final created = await _firestoreService.createTicketType(ticket);
      _ticketTypes.add(created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateTicketType(TicketType ticket) async {
    try {
      final updated = await _firestoreService.updateTicketType(ticket);
      final index = _ticketTypes.indexWhere((t) => t.id == ticket.id);
      if (index >= 0) {
        _ticketTypes[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteTicketType(String ticketId) async {
    try {
      await _firestoreService.deleteTicketType(ticketId);
      _ticketTypes.removeWhere((t) => t.id == ticketId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== Registrations ====================

  Future<void> loadRegistrations(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registrations = await _firestoreService.getRegistrations(eventId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Registration?> createRegistration(Registration registration) async {
    try {
      final created = await _firestoreService.createRegistration(registration);
      _registrations.add(created);

      // Increment sold count for ticket type
      final ticketIndex =
          _ticketTypes.indexWhere((t) => t.id == registration.ticketTypeId);
      if (ticketIndex >= 0) {
        _ticketTypes[ticketIndex] = _ticketTypes[ticketIndex].copyWith(
          sold: _ticketTypes[ticketIndex].sold + 1,
        );
      }

      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateRegistrationStatus(
      String regId, RegistrationStatus status) async {
    try {
      final index = _registrations.indexWhere((r) => r.id == regId);
      if (index >= 0) {
        final updated = _registrations[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateRegistration(updated);
        _registrations[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== Promo Codes ====================

  Future<void> loadPromoCodes(String eventId) async {
    try {
      _promoCodes = await _firestoreService.getPromoCodes(eventId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  PromoCode? validatePromoCode(String code, String? ticketId) {
    final promo = _promoCodes.firstWhere(
      (p) => p.code.toUpperCase() == code.toUpperCase() && p.isValid,
      orElse: () => PromoCode(
        id: '',
        eventId: '',
        code: '',
        value: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (promo.id.isEmpty) return null;

    // Check if applicable to this ticket
    if (promo.applicableTicketIds != null &&
        ticketId != null &&
        !promo.applicableTicketIds!.contains(ticketId)) {
      return null;
    }

    return promo;
  }

  Future<PromoCode?> createPromoCode(PromoCode promo) async {
    try {
      final created = await _firestoreService.createPromoCode(promo);
      _promoCodes.add(created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
