import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/registration.dart';

/// Mock Firestore service for development without Firebase
/// Replace with actual Cloud Firestore calls when Firebase is configured
class FirestoreService {
  final _uuid = const Uuid();

  // In-memory mock data stores
  final Map<String, Organization> _organizations = {};
  final Map<String, Event> _events = {};
  final Map<String, List<Attendee>> _attendees = {};
  final Map<String, BadgeTemplate> _templates = {};

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create demo organization
    final orgId = 'org_demo';
    _organizations[orgId] = Organization(
      id: orgId,
      name: 'Demo Organization',
      ownerEmail: 'demo@badgeboss.app',
      ownerId: 'user_demo',
      eventsUsed: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create demo event
    final eventId = 'event_demo';
    _events[eventId] = Event(
      id: eventId,
      name: 'Tech Conference 2024',
      description: 'Annual technology conference',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 2)),
      venue: 'Convention Center',
      venueAddress: '123 Main Street, Tech City',
      organizationId: orgId,
      stats: EventStats(
        totalRegistered: 150,
        totalCheckedIn: 45,
        checkinsByCategory: {
          'general': 30,
          'vip': 10,
          'speaker': 5,
        },
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'user_demo',
    );

    // Create demo attendees
    _attendees[eventId] = _generateMockAttendees(eventId, orgId, 150);

    // Create demo badge template
    _templates['template_default'] = BadgeTemplate(
      id: 'template_default',
      name: 'Standard Conference Badge',
      organizationId: orgId,
      widthMm: 100,
      heightMm: 70,
      zplTemplate: '''
^XA
^CF0,40
^FO50,30^FD{{firstName}} {{lastName}}^FS
^CF0,25
^FO50,80^FD{{company}}^FS
^CF0,20
^FO50,115^FD{{title}}^FS
^FO300,30^BQN,2,5^FDQA,{{qrCode}}^FS
^FO0,150^GB400,20,20,B^FS
^XZ
''',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<Attendee> _generateMockAttendees(
      String eventId, String orgId, int count) {
    final categories = ['general', 'vip', 'speaker', 'sponsor', 'staff'];
    final companies = [
      'TechCorp',
      'InnovateLab',
      'DataDrive',
      'CloudScale',
      'AppWorks',
      'DevStudio',
      'AI Solutions',
      'CyberNet',
      'DigiFlow',
      'CodeBase'
    ];
    final titles = [
      'Software Engineer',
      'Product Manager',
      'CTO',
      'CEO',
      'Developer',
      'Designer',
      'Data Scientist',
      'DevOps Engineer',
      'Architect',
      'Manager'
    ];
    final firstNames = [
      'Alex',
      'Jordan',
      'Taylor',
      'Morgan',
      'Casey',
      'Riley',
      'Quinn',
      'Parker',
      'Avery',
      'Cameron',
      'Drew',
      'Skyler',
      'Reese',
      'Dakota'
    ];
    final lastNames = [
      'Smith',
      'Johnson',
      'Williams',
      'Brown',
      'Jones',
      'Garcia',
      'Miller',
      'Davis',
      'Rodriguez',
      'Martinez',
      'Hernandez',
      'Lopez',
      'Wilson',
      'Anderson'
    ];

    return List.generate(count, (i) {
      final firstName = firstNames[i % firstNames.length];
      final lastName = lastNames[i % lastNames.length];
      final id = _uuid.v4();

      return Attendee(
        id: id,
        firstName:
            '$firstName ${String.fromCharCode(65 + (i ~/ firstNames.length))}.',
        lastName: lastName,
        email:
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}$i@example.com',
        company: companies[i % companies.length],
        title: titles[i % titles.length],
        category: categories[i % categories.length],
        qrCode: 'BB-$eventId-$id',
        checkinStatusMap: i < 45
            ? CheckinStatus(
                isCheckedIn: true,
                checkedInAt: DateTime.now().subtract(Duration(minutes: i * 2)),
                checkInMethod: 'qr',
                checkedInBy: 'staff_demo',
                deviceId: 'device_1',
              ).toMap()
            : {},
        eventId: eventId,
        organizationId: orgId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  // ==================== Organization Operations ====================

  Future<Organization?> getOrganization(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _organizations[orgId];
  }

  Future<Organization> createOrganization(Organization org) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _organizations[org.id] = org;
    return org;
  }

  // ==================== Event Operations ====================

  Future<List<Event>> getEvents(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _events.values.where((e) => e.organizationId == orgId).toList();
  }

  Future<Event?> getEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _events[eventId];
  }

  Future<Event> createEvent(Event event) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Check freemium limit
    final org = _organizations[event.organizationId];
    if (org != null && org.hasReachedLimit) {
      throw Exception('Event limit reached. Please upgrade your plan.');
    }

    _events[event.id] = event;
    _attendees[event.id] = [];

    // Increment events used
    if (org != null) {
      _organizations[org.id] = org.copyWith(
        eventsUsed: org.eventsUsed + 1,
        updatedAt: DateTime.now(),
      );
    }

    return event;
  }

  Future<Event> updateEvent(Event event) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _events[event.id] = event;
    return event;
  }

  Future<void> deleteEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _events.remove(eventId);
    _attendees.remove(eventId);
  }

  // ==================== Attendee Operations ====================

  Future<List<Attendee>> getAttendees(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _attendees[eventId] ?? [];
  }

  Future<Attendee?> getAttendee(String eventId, String attendeeId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _attendees[eventId]?.firstWhere(
      (a) => a.id == attendeeId,
      orElse: () => throw Exception('Attendee not found'),
    );
  }

  Future<Attendee?> getAttendeeByQrCode(String eventId, String qrCode) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final attendees = _attendees[eventId] ?? [];
    try {
      return attendees.firstWhere((a) => a.qrCode == qrCode);
    } catch (e) {
      return null;
    }
  }

  Future<List<Attendee>> searchAttendees(String eventId, String query) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final attendees = _attendees[eventId] ?? [];
    final lowerQuery = query.toLowerCase();

    return attendees.where((a) {
      return a.fullName.toLowerCase().contains(lowerQuery) ||
          a.email.toLowerCase().contains(lowerQuery) ||
          (a.company?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<Attendee> createAttendee(Attendee attendee) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _attendees.putIfAbsent(attendee.eventId, () => []);
    _attendees[attendee.eventId]!.add(attendee);

    // Update event stats
    await _updateEventStats(attendee.eventId);

    return attendee;
  }

  Future<Attendee> updateAttendee(Attendee attendee) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _attendees[attendee.eventId];
    if (list != null) {
      final index = list.indexWhere((a) => a.id == attendee.id);
      if (index >= 0) {
        list[index] = attendee;
      }
    }

    // Update event stats
    await _updateEventStats(attendee.eventId);

    return attendee;
  }

  Future<int> bulkCreateAttendees(List<Attendee> attendees) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (attendees.isEmpty) return 0;

    final eventId = attendees.first.eventId;
    _attendees.putIfAbsent(eventId, () => []);
    _attendees[eventId]!.addAll(attendees);

    await _updateEventStats(eventId);
    return attendees.length;
  }

  Future<void> _updateEventStats(String eventId) async {
    final attendees = _attendees[eventId] ?? [];
    final event = _events[eventId];
    if (event == null) return;

    final checkedIn = attendees.where((a) => a.isCheckedIn).toList();
    final byCategory = <String, int>{};

    for (final a in checkedIn) {
      byCategory[a.category] = (byCategory[a.category] ?? 0) + 1;
    }

    _events[eventId] = event.copyWith(
      stats: event.stats.copyWith(
        totalRegistered: attendees.length,
        totalCheckedIn: checkedIn.length,
        checkinsByCategory: byCategory,
      ),
      updatedAt: DateTime.now(),
    );
  }

  // ==================== Badge Template Operations ====================

  Future<List<BadgeTemplate>> getTemplates(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _templates.values.where((t) => t.organizationId == orgId).toList();
  }

  Future<BadgeTemplate?> getTemplate(String templateId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _templates[templateId];
  }

  Future<BadgeTemplate> createTemplate(BadgeTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _templates[template.id] = template;
    return template;
  }

  // ==================== Ticket Type Operations ====================

  final Map<String, List<TicketType>> _ticketTypes = {};
  final Map<String, List<Registration>> _registrations = {};
  final Map<String, List<PromoCode>> _promoCodes = {};

  Future<List<TicketType>> getTicketTypes(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _ticketTypes[eventId] ?? [];
  }

  Future<TicketType> createTicketType(TicketType ticket) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _ticketTypes.putIfAbsent(ticket.eventId, () => []);
    _ticketTypes[ticket.eventId]!.add(ticket);
    return ticket;
  }

  Future<TicketType> updateTicketType(TicketType ticket) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _ticketTypes[ticket.eventId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == ticket.id);
      if (index >= 0) list[index] = ticket;
    }
    return ticket;
  }

  Future<void> deleteTicketType(String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final list in _ticketTypes.values) {
      list.removeWhere((t) => t.id == ticketId);
    }
  }

  // ==================== Registration Operations ====================

  Future<List<Registration>> getRegistrations(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _registrations[eventId] ?? [];
  }

  Future<Registration> createRegistration(Registration registration) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _registrations.putIfAbsent(registration.eventId, () => []);
    _registrations[registration.eventId]!.add(registration);
    return registration;
  }

  Future<Registration> updateRegistration(Registration registration) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _registrations[registration.eventId];
    if (list != null) {
      final index = list.indexWhere((r) => r.id == registration.id);
      if (index >= 0) list[index] = registration;
    }
    return registration;
  }

  // ==================== Promo Code Operations ====================

  Future<List<PromoCode>> getPromoCodes(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _promoCodes[eventId] ?? [];
  }

  Future<PromoCode> createPromoCode(PromoCode promo) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _promoCodes.putIfAbsent(promo.eventId, () => []);
    _promoCodes[promo.eventId]!.add(promo);
    return promo;
  }
}
