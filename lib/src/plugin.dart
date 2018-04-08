import 'messages/subscriber.dart';
import 'messages/sender.dart';

class Plugin {
  final Subscriber _subscriber;
  final Sender _sender;
  final String name;
  final Map<String, dynamic> internals;

  Plugin(this.name, this._sender, this._subscriber, this.internals);

  void listen(String channel, SubscriberCallback callback) {
    _subscriber.listen(channel, callback);
  }

  void send(String channel, Map<dynamic, dynamic> payload) {
    _sender.send(channel, payload);
  }

  void sendFrom(Plugin plugin, String channel, Map<dynamic, dynamic> payload) {
    _sender.sendFrom(plugin.name, channel, payload);
  }
}
