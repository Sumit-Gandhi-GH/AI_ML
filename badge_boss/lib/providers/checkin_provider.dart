import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/attendee.dart';
import '../services/offline_sync_service.dart';

/// Check-in result
enum CheckinResult {
  success,
  alreadyCheckedIn,
  attendeeNotFound,
  error,
}

/// Check-in response with details
class CheckinResponse {
  final CheckinResult result;
  final Attendee? attendee;
  final DateTime? previousCheckinTime;
  final String? errorMessage;

  CheckinResponse({
    required this.result,
    this.attendee,
    this.previousCheckinTime,
    this.errorMessage,
  });
}

/// Check-in provider with offline support
class CheckinProvider with ChangeNotifier {
  final OfflineSyncService _offlineSyncService;
  final _uuid = const Uuid();

  String _currentEventId = '';
  String _currentUserId = 'staff_demo';
  String _currentDeviceId = 'device_1';
  bool _isProcessing = false;
  CheckinResponse? _lastResponse;

  CheckinProvider(this._offlineSyncService);

  bool get isProcessing => _isProcessing;
  bool get isOnline => _offlineSyncService.isOnline;
  int get pendingCount => _offlineSyncService.pendingCheckinCount;
  CheckinResponse? get lastResponse => _lastResponse;

  void configure({
    required String eventId,
    required String userId,
    required String deviceId,
  }) {
    _currentEventId = eventId;
    _currentUserId = userId;
    _currentDeviceId = deviceId;
  }

  /// Process QR code scan
  Future<CheckinResponse> processQrScan(String qrCode) async {
    return _performCheckin(qrCode: qrCode, method: 'qr');
  }

  /// Process NFC scan
  Future<CheckinResponse> processNfcScan(String nfcData) async {
    return _performCheckin(qrCode: nfcData, method: 'nfc');
  }

  /// Process manual check-in
  Future<CheckinResponse> processManualCheckin(Attendee attendee) async {
    return _performCheckinForAttendee(attendee, 'manual');
  }

  Future<CheckinResponse> _performCheckin({
    required String qrCode,
    required String method,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Find attendee by QR code
      final attendee = _offlineSyncService.findAttendeeByQrCode(
        _currentEventId, qrCode);

      if (attendee == null) {
        _lastResponse = CheckinResponse(
          result: CheckinResult.attendeeNotFound,
          errorMessage: 'No attendee found with this code',
        );
        return _lastResponse!;
      }

      return await _performCheckinForAttendee(attendee, method);
    } catch (e) {
      _lastResponse = CheckinResponse(
        result: CheckinResult.error,
        errorMessage: e.toString(),
      );
      return _lastResponse!;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<CheckinResponse> _performCheckinForAttendee(
    Attendee attendee,
    String method,
  ) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Check for duplicate
      if (attendee.isCheckedIn) {
        _lastResponse = CheckinResponse(
          result: CheckinResult.alreadyCheckedIn,
          attendee: attendee,
          previousCheckinTime: attendee.checkinStatus.checkedInAt,
        );
        return _lastResponse!;
      }

      // Perform check-in
      final updatedAttendee = attendee.checkIn(
        method: method,
        checkedInBy: _currentUserId,
        deviceId: _currentDeviceId,
      );

      // Update local cache
      await _offlineSyncService.updateCachedAttendee(
        _currentEventId, updatedAttendee);

      // Queue for sync if offline
      if (!_offlineSyncService.isOnline) {
        await _offlineSyncService.queueCheckin(PendingCheckin(
          id: _uuid.v4(),
          attendeeId: attendee.id,
          eventId: _currentEventId,
          action: 'checkin',
          method: method,
          performedBy: _currentUserId,
          deviceId: _currentDeviceId,
          timestamp: DateTime.now(),
        ));
      }

      _lastResponse = CheckinResponse(
        result: CheckinResult.success,
        attendee: updatedAttendee,
      );
      return _lastResponse!;
    } catch (e) {
      _lastResponse = CheckinResponse(
        result: CheckinResult.error,
        errorMessage: e.toString(),
      );
      return _lastResponse!;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Undo check-in
  Future<CheckinResponse> undoCheckin(Attendee attendee) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final updatedAttendee = attendee.undoCheckIn();

      await _offlineSyncService.updateCachedAttendee(
        _currentEventId, updatedAttendee);

      if (!_offlineSyncService.isOnline) {
        await _offlineSyncService.queueCheckin(PendingCheckin(
          id: _uuid.v4(),
          attendeeId: attendee.id,
          eventId: _currentEventId,
          action: 'undo_checkin',
          method: 'manual',
          performedBy: _currentUserId,
          deviceId: _currentDeviceId,
          timestamp: DateTime.now(),
        ));
      }

      _lastResponse = CheckinResponse(
        result: CheckinResult.success,
        attendee: updatedAttendee,
      );
      return _lastResponse!;
    } catch (e) {
      _lastResponse = CheckinResponse(
        result: CheckinResult.error,
        errorMessage: e.toString(),
      );
      return _lastResponse!;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearLastResponse() {
    _lastResponse = null;
    notifyListeners();
  }
}
