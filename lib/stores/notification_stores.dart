import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';
import '../services/notifications_service.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore(this._service);

  final NotificationService _service;

  List<NotificationItem> _items = const [];
  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;
  String? _error;

  List<NotificationItem> get items => _items;
  bool get isLoading => _loading;
  bool get hasLoaded => _loaded;
  String? get error => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _notify();

    try {
      _items = await _service.fetch();
      _loaded = true;
    } on NotificationException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = kDebugMode
          ? 'Failed to load: $e'
          : 'Failed to load notifications';
    }

    _loading = false;
    _notify();
  }

  /// Optimistic: flips locally, then tells the server. Failures are
  /// ignored; the next [load] restores the server state.
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].isRead) return;

    _items = [..._items]..[i] = _items[i].copyWith(isRead: true);
    _notify();

    try {
      await _service.markRead(id);
    } catch (e) {
      debugPrint('[Notifications] markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    final unread = _items.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unread.isEmpty) return;

    _items = [for (final n in _items) n.copyWith(isRead: true)];
    _notify();

    await Future.wait(
      unread.map(
        (id) => _service.markRead(id).catchError((Object e) {
          debugPrint('[Notifications] markRead failed: $e');
        }),
      ),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
