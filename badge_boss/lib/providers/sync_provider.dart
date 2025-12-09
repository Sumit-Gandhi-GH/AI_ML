import 'package:flutter/foundation.dart';
import '../services/offline_sync_service.dart';

/// Provider for sync status and connectivity
class SyncProvider with ChangeNotifier {
  final OfflineSyncService _offlineSyncService;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;

  SyncProvider(this._offlineSyncService) {
    _offlineSyncService.onConnectivityChanged = _onConnectivityChanged;
    _offlineSyncService.onCheckinSynced = _onCheckinSynced;
    _isOnline = _offlineSyncService.isOnline;
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  bool get hasPendingActions => _pendingCount > 0;

  void _onConnectivityChanged(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  void _onCheckinSynced(PendingCheckin checkin) {
    _pendingCount = _offlineSyncService.pendingCheckinCount;
    notifyListeners();
  }

  Future<void> syncNow() async {
    _isSyncing = true;
    notifyListeners();

    await _offlineSyncService.syncPendingCheckins();

    _isSyncing = false;
    _pendingCount = _offlineSyncService.pendingCheckinCount;
    notifyListeners();
  }

  void refresh() {
    _pendingCount = _offlineSyncService.pendingCheckinCount;
    _isOnline = _offlineSyncService.isOnline;
    notifyListeners();
  }
}
