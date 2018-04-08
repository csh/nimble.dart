import 'dart:isolate';
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as Path;

import 'messages/subscriber.dart';
import 'messages/sender.dart';
import 'plugin.dart';

class PluginManager {
  final Map<String, Plugin> _plugins = new Map();

  Future<Plugin> load(Directory directory,
      [List<String> args = null, String name]) async {
    name = name != null ? name : "dummy";
    args = args != null ? args : [];

    var receiver = new ReceivePort();
    var completer = new Completer();

    var isolate = await _isolate(directory, args, receiver.sendPort);
    var subscription = receiver.listen(null);
    var timeout = new Timer(new Duration(milliseconds: 5000), () {
      throw "Failed to initialise plugin '$name' in time";
    });
    subscription.onData((SendPort contact) {
      timeout.cancel();
      contact.send({"name": name});

      var subscriber = new Subscriber(subscription);
      var sender = new Sender(contact);
      var internals = <String, dynamic>{
        "pluginManager": this,
        "subscription": subscription,
        "isolate": isolate,
        "rp": receiver,
        "sp": contact,
      };
      var plugin = new Plugin(name, sender, subscriber, internals);
      _plugins[name] = plugin;
      completer.complete(plugin);
    });
    isolate.resume(isolate.pauseCapability);
    return completer.future;
  }

  Future<Isolate> _isolate(
      Directory directory, List<String> args, var initialMessage) {
    var path = Path.join(directory.absolute.path, "bin", "main.dart");
    return Isolate.spawnUri(new Uri.file(path), args, initialMessage,
        paused: true);
  }
}
