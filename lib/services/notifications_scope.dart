import 'package:flutter/widgets.dart';

import '../stores/notification_stores.dart';

class NotificationScope extends InheritedNotifier<NotificationStore> {
  const NotificationScope({
    super.key,
    required NotificationStore store,
    required super.child,
  }) : super(notifier: store);

  static NotificationStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NotificationScope>();
    assert(scope != null, 'No NotificationScope found in context');
    return scope!.notifier!;
  }
}