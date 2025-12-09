import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';

/// Firebase service for production backend
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _organizations => _firestore.collection('organizations');
  
  CollectionReference _events(String orgId) => 
      _organizations.doc(orgId).collection('events');
  
  CollectionReference _attendees(String orgId, String eventId) => 
      _organizations.doc(orgId).collection('events').doc(eventId).collection('attendees');
  
  CollectionReference _checkinLogs(String orgId, String eventId) => 
      _organizations.doc(orgId).collection('events').doc(eventId).collection('checkinLogs');
  
  CollectionReference _badgeTemplates(String orgId) =>
      _organizations.doc(orgId).collection('badgeTemplates');

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== Authentication ====================

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==================== Organizations ====================

  Future<Organization?> getOrganization(String orgId) async {
    final doc = await _organizations.doc(orgId).get();
    if (!doc.exists) return null;
    return Organization.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<Organization> createOrganization(Organization org) async {
    await _organizations.doc(org.id).set(org.toMap());
    return org;
  }

  Future<void> updateOrganization(Organization org) async {
    await _organizations.doc(org.id).update(org.toMap());
  }

  Stream<Organization?> watchOrganization(String orgId) {
    return _organizations.doc(orgId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Organization.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ==================== Events ====================

  Future<List<Event>> getEvents(String orgId) async {
    final snapshot = await _events(orgId).orderBy('startDate', descending: true).get();
    return snapshot.docs.map((doc) {
      return Event.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<Event?> getEvent(String orgId, String eventId) async {
    final doc = await _events(orgId).doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<Event> createEvent(String orgId, Event event) async {
    // Check freemium limit using transaction
    return await _firestore.runTransaction((transaction) async {
      final orgDoc = await transaction.get(_organizations.doc(orgId));
      
      if (!orgDoc.exists) {
        throw Exception('Organization not found');
      }

      final org = Organization.fromMap(
        orgDoc.data() as Map<String, dynamic>, 
        orgDoc.id,
      );

      if (org.hasReachedLimit) {
        throw Exception('Event limit reached. Please upgrade your plan.');
      }

      // Create event
      final eventRef = _events(orgId).doc(event.id);
      transaction.set(eventRef, event.toMap());

      // Increment events used
      transaction.update(_organizations.doc(orgId), {
        'eventsUsed': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return event;
    });
  }

  Future<void> updateEvent(String orgId, Event event) async {
    await _events(orgId).doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String orgId, String eventId) async {
    // Delete all subcollections first
    final attendeesSnapshot = await _attendees(orgId, eventId).get();
    for (final doc in attendeesSnapshot.docs) {
      await doc.reference.delete();
    }

    await _events(orgId).doc(eventId).delete();

    // Decrement events used
    await _organizations.doc(orgId).update({
      'eventsUsed': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Event?> watchEvent(String orgId, String eventId) {
    return _events(orgId).doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Event.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ==================== Attendees ====================

  Future<List<Attendee>> getAttendees(String orgId, String eventId) async {
    final snapshot = await _attendees(orgId, eventId)
        .orderBy('lastName')
        .get();
    return snapshot.docs.map((doc) {
      return Attendee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<Attendee?> getAttendee(String orgId, String eventId, String attendeeId) async {
    final doc = await _attendees(orgId, eventId).doc(attendeeId).get();
    if (!doc.exists) return null;
    return Attendee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<Attendee?> getAttendeeByQrCode(String orgId, String eventId, String qrCode) async {
    final snapshot = await _attendees(orgId, eventId)
        .where('qrCode', isEqualTo: qrCode)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return Attendee.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  Future<List<Attendee>> searchAttendees(
    String orgId, 
    String eventId, 
    String query,
  ) async {
    // Firestore doesn't support full-text search natively
    // For production, use Algolia or ElasticSearch
    // This is a simple prefix search on lastName
    final snapshot = await _attendees(orgId, eventId)
        .orderBy('lastName')
        .startAt([query.toLowerCase()])
        .endAt(['${query.toLowerCase()}\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      return Attendee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<Attendee> createAttendee(String orgId, String eventId, Attendee attendee) async {
    await _attendees(orgId, eventId).doc(attendee.id).set(attendee.toMap());
    
    // Update event stats
    await _updateEventStats(orgId, eventId);
    
    return attendee;
  }

  Future<void> createAttendeeBatch(
    String orgId, 
    String eventId, 
    List<Attendee> attendees,
  ) async {
    final batch = _firestore.batch();
    
    for (final attendee in attendees) {
      batch.set(
        _attendees(orgId, eventId).doc(attendee.id),
        attendee.toMap(),
      );
    }

    await batch.commit();
    await _updateEventStats(orgId, eventId);
  }

  Future<void> updateAttendee(String orgId, String eventId, Attendee attendee) async {
    await _attendees(orgId, eventId).doc(attendee.id).update(attendee.toMap());
    await _updateEventStats(orgId, eventId);
  }

  Future<void> deleteAttendee(String orgId, String eventId, String attendeeId) async {
    await _attendees(orgId, eventId).doc(attendeeId).delete();
    await _updateEventStats(orgId, eventId);
  }

  Stream<List<Attendee>> watchAttendees(String orgId, String eventId) {
    return _attendees(orgId, eventId)
        .orderBy('lastName')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Attendee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  // ==================== Check-in ====================

  Future<Attendee> checkInAttendee({
    required String orgId,
    required String eventId,
    required Attendee attendee,
    required String method,
    required String checkedInBy,
    required String deviceId,
  }) async {
    final updatedAttendee = attendee.checkIn(
      method: method,
      checkedInBy: checkedInBy,
      deviceId: deviceId,
    );

    // Use transaction for atomicity
    await _firestore.runTransaction((transaction) async {
      transaction.update(
        _attendees(orgId, eventId).doc(attendee.id),
        updatedAttendee.toMap(),
      );

      // Add check-in log
      final logRef = _checkinLogs(orgId, eventId).doc();
      transaction.set(logRef, {
        'attendeeId': attendee.id,
        'eventId': eventId,
        'organizationId': orgId,
        'action': 'checkin',
        'method': method,
        'performedBy': checkedInBy,
        'deviceId': deviceId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });

    await _updateEventStats(orgId, eventId);
    return updatedAttendee;
  }

  Future<void> _updateEventStats(String orgId, String eventId) async {
    // Get aggregated stats
    final attendeesSnapshot = await _attendees(orgId, eventId).get();
    final attendees = attendeesSnapshot.docs.map((doc) {
      return Attendee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    final checkedIn = attendees.where((a) => a.isCheckedIn).toList();
    final byCategory = <String, int>{};
    
    for (final a in checkedIn) {
      byCategory[a.category] = (byCategory[a.category] ?? 0) + 1;
    }

    await _events(orgId).doc(eventId).update({
      'stats.totalRegistered': attendees.length,
      'stats.totalCheckedIn': checkedIn.length,
      'stats.checkinsByCategory': byCategory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== Badge Templates ====================

  Future<List<BadgeTemplate>> getTemplates(String orgId) async {
    final snapshot = await _badgeTemplates(orgId).get();
    return snapshot.docs.map((doc) {
      return BadgeTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<BadgeTemplate?> getTemplate(String orgId, String templateId) async {
    final doc = await _badgeTemplates(orgId).doc(templateId).get();
    if (!doc.exists) return null;
    return BadgeTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<BadgeTemplate> createTemplate(String orgId, BadgeTemplate template) async {
    await _badgeTemplates(orgId).doc(template.id).set(template.toMap());
    return template;
  }

  Future<void> updateTemplate(String orgId, BadgeTemplate template) async {
    await _badgeTemplates(orgId).doc(template.id).update(template.toMap());
  }

  // ==================== Storage ====================

  Future<String> uploadAttendeePhoto(
    String orgId,
    String eventId,
    String attendeeId,
    List<int> imageBytes,
  ) async {
    final ref = _storage
        .ref()
        .child('organizations/$orgId/events/$eventId/attendees/$attendeeId/photo.jpg');
    
    await ref.putData(
      Uint8List.fromList(imageBytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }

  Future<String> uploadEventLogo(
    String orgId,
    String eventId,
    List<int> imageBytes,
  ) async {
    final ref = _storage
        .ref()
        .child('organizations/$orgId/events/$eventId/logo.png');
    
    await ref.putData(
      Uint8List.fromList(imageBytes),
      SettableMetadata(contentType: 'image/png'),
    );

    return await ref.getDownloadURL();
  }
}
