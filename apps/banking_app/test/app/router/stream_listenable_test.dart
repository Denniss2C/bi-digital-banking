import 'dart:async';

import 'package:banking_app/app/router/stream_listenable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notifies on every session event and stops once disposed', () async {
    final session = StreamController<Object?>();
    final listenable = StreamListenable(session.stream);
    var notifications = 0;
    listenable.addListener(() => notifications++);

    session
      ..add('signed in')
      ..add(null);
    await pumpEventQueue();
    expect(notifications, 2);

    listenable.dispose();
    expect(session.hasListener, isFalse);
    await session.close();
  });
}
