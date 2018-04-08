import 'dart:isolate';

import 'messages/subscriber.dart';
import 'messages/sender.dart';

class PluginInterface {
  final ReceivePort _receivePort;
  final SendPort _sendPort;

  Subscriber _subscriber;
  Sender _sender;

  PluginInterface(this._sendPort) : _receivePort = new ReceivePort() {
    var subscription = _receivePort.listen(null);
    _sendPort.send(_receivePort.sendPort);
    _subscriber = new Subscriber(subscription);
    _sender = new Sender(_sendPort);
  }

  void listen(String channel, SubscriberCallback callback) {
    _subscriber.listen(channel, callback);
  }

  void send(String channel, Map<dynamic, dynamic> payload) {
    _sender.send(channel, payload);
  }
}