import 'dart:isolate';

class Sender {
  final SendPort _sender;

  Sender(this._sender);

  void send(String channel, Map<dynamic, dynamic> payload) {
    var message = _wrap(channel, payload);
    _sender.send(message);
  }

  void sendTo(String target, String chatterChannel, String channel, Map<dynamic, dynamic> payload) {
    payload = new Map.from(payload);
    payload.addAll({
      "::target": {
        "channel": channel,
        "name": target
      }
    });
    var message = _wrap(chatterChannel, payload);
    _sender.send(message);
  }

  Map<String, dynamic> _wrap(String channel, Map<dynamic, dynamic> payload) {
    return {"channel": channel, "payload": payload};
  }
}