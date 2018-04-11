import 'dart:isolate';

import 'messages/subscriber.dart';
import 'messages/sender.dart';
import 'aliases.dart' as aliases;

class Plugin {
  final Subscriber _subscriber;
  final Isolate _isolate;
  final Sender _sender;
  final String name;
  final Map<String, dynamic> internals;

  bool get isLoaded => _isLoaded;
  bool _isLoaded = true;

  Plugin(
      this.name, this._sender, this._subscriber, this._isolate, this.internals);

  void listen(String channel, SubscriberCallback callback) {
    if (!isLoaded) throw "plugin \"$name\" is no longer loaded";
    _subscriber.listen(channel, callback);
  }

  void send(String channel, Map<String, dynamic> payload) {
    if (!isLoaded) throw "plugin \"$name\" is no longer loaded";
    _sender.send(channel, payload);
  }

  void unload() {
    if (!isLoaded) throw "plugin \"$name\" has already been unloaded";
    _sender.send(aliases.channelControl, {"command": "terminate"});
    _subscriber.close();
    _isLoaded = false;
  }

  String toString() {
    return "Plugin: ${name}";
  }
}
