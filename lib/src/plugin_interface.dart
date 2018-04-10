import 'dart:isolate';

import 'messages/subscriber.dart';
import 'messages/sender.dart';

class PluginInterface {
  final ReceivePort _receivePort;
  final SendPort _sendPort;
  final String name;

  Subscriber _subscriber;
  Sender _sender;
  
  PluginInterface(message) : name = message["name"], _sendPort = message["port"], _receivePort = new ReceivePort() {
    var subscription = _receivePort.listen(null);
    _sendPort.send(_receivePort.sendPort);
    _subscriber = new Subscriber(subscription);
    _sender = new Sender(_sendPort);

    listen("nimble:control", (channel, payload) {
      if (payload["command"] == "terminate") {
        _subscriber.close();
        Isolate.current.kill();
      }
    });
  }

  void listen(String channel, SubscriberCallback callback) {
    _subscriber.listen(channel, callback);
  }

  void send(String channel, Map<String, dynamic> payload) {
    _sender.send(channel, payload);
  }
}