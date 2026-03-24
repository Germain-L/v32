import 'package:flutter/foundation.dart';

/// Represents the current sync status
class SyncStatus {
  final DateTime? lastSync;
  final int pendingChanges;
  final bool isSyncing;
  final String? error;
  final bool isOnline;

  const SyncStatus({
    this.lastSync,
    this.pendingChanges = 0,
    this.isSyncing = false,
    this.error,
    this.isOnline = true,
  });

  SyncStatus copyWith({
    DateTime? lastSync,
    int? pendingChanges,
    bool? isSyncing,
    String? error,
    bool? isOnline,
    bool clearError = false,
  }) {
    return SyncStatus(
      lastSync: lastSync ?? this.lastSync,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      isOnline: isOnline ?? this.isOnline,
    );
  }

  String get displayText {
    if (!isOnline) return 'Offline';
    if (isSyncing) return 'Syncing...';
    if (error != null) return 'Sync error';
    if (pendingChanges > 0) return '$pendingChanges pending';
    if (lastSync == null) return 'Never synced';
    return 'Synced';
  }

  bool get needsSync => pendingChanges > 0 || lastSync == null;
}

/// Provider that tracks and exposes sync status
class SyncStatusProvider extends ChangeNotifier {
  SyncStatus _status = const SyncStatus();

  SyncStatus get status => _status;

  void updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void setSyncing(bool isSyncing) {
    _status = _status.copyWith(isSyncing: isSyncing);
    notifyListeners();
  }

  void setOnline(bool isOnline) {
    _status = _status.copyWith(isOnline: isOnline);
    notifyListeners();
  }

  void setPendingChanges(int count) {
    _status = _status.copyWith(pendingChanges: count);
    notifyListeners();
  }

  void setLastSync(DateTime? lastSync) {
    _status = _status.copyWith(lastSync: lastSync);
    notifyListeners();
  }

  void setError(String? error) {
    _status = _status.copyWith(error: error);
    notifyListeners();
  }

  void clearError() {
    _status = _status.copyWith(clearError: true);
    notifyListeners();
  }
}
