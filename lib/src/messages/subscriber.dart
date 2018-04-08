import 'dart:async';

typedef void SubscriberCallback(String channel, Map<dynamic, dynamic> data);

class Subscriber {
  final Map<String, SubscriberCallback> _handlers = new Map();
  final StreamSubscription _subscription;

  Subscriber(this._subscription) {
    _subscription.onData(_handle);
  }

  void listen(String channel, SubscriberCallback callback) {
    _handlers[channel] = callback;
  }

  void close() {
    _subscription.cancel();
  }

  void _handle(message) {
    var channel = message["channel"] as String;
    var handler = _handlers[channel];
    if (handler != null) {
      var payload = message["payload"] as Map<dynamic, dynamic>;
      handler(channel, payload);
    }
  }
}
