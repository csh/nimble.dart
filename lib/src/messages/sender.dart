import 'dart:isolate';

class Sender {
  final SendPort _sender;

  Sender(this._sender);

  void send(String channel, Map<dynamic, dynamic> payload) {
    var message = _wrap(channel, null, payload);
    _sender.send(message);
  }

  void sendFrom(String sender, String channel, Map<dynamic, dynamic> payload) {
    var message = _wrap(channel, {"sender": sender}, payload);
    _sender.send(message);
  }

  Map<String, dynamic> _wrap(String channel, Map<String, dynamic> headers,
      Map<dynamic, dynamic> payload) {
    var message = {"channel": channel, "payload": payload};
    if (headers != null) headers.forEach(message.putIfAbsent);
    return message;
  }
}
