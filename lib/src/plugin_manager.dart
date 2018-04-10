import 'dart:isolate';
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as Path;
import 'package:yaml/yaml.dart' as Yaml;

import 'messages/subscriber.dart';
import 'messages/sender.dart';
import 'aliases.dart' as aliases;
import 'plugin.dart';

class PluginManager {
  final Map<String, Plugin> _plugins = new Map();

  Future<List<Plugin>> loadAll(Directory directory,
      [Map<String, List<String>> pluginArgs = null]) async {
    pluginArgs = pluginArgs ?? {};
    var futures = new List<Future<Plugin>>();
    var entities = directory.listSync();
    entities.retainWhere((entity) => entity is Directory);
    for (var target in entities) {
      _validateDirectory(target);
      var name = await _getPluginName(target);
      futures.add(_load(target, name, pluginArgs[name] ?? []));
    }
    return Future.wait(futures);
  }

  Future<Plugin> load(Directory directory,
      [String name = null, List<String> args = null]) async {
    _validateDirectory(directory);
    if (name == null) {
      name = await _getPluginName(directory);
    }
    return _load(directory, name, args ?? []);
  }

  Future<Plugin> _load(
      Directory directory, String name, List<String> args) async {
    if (_plugins.containsKey(name)) {
      throw "Duplicate plugin load detected. Name: ${name}, Directory: ${directory.path}";
    }
    var receiver = new ReceivePort();
    var completer = new Completer();
    var isolate = await _isolate(
        directory, args, {"name": name, "port": receiver.sendPort});
    var timeout = new Timer(new Duration(milliseconds: 5000), () {
      throw "Failed to initialise plugin '$name' in time";
    });
    var subscription = receiver.listen(null);
    subscription.onData((SendPort contact) {
      timeout.cancel();
      var subscriber = new Subscriber(subscription);
      var sender = new Sender(contact);
      var internals = <String, dynamic>{
        "pluginManager": this,
        "subscription": subscription,
        "isolate": isolate,
        "rp": receiver,
        "sp": contact,
      };
      var plugin = new Plugin(name, sender, subscriber, isolate, internals);
      _plugins[name] = plugin;
      _subscribeControlChannels(plugin);
      completer.complete(plugin);
    });
    isolate.addOnExitListener(receiver.sendPort, response: {
      "channel": aliases.channelControl,
      "payload": {"status": "terminated"}
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

  Future _validateDirectory(Directory directory) async {
    var file = new File(Path.join(directory.path, "pubspec.yaml"));
    if (!await file.exists()) throw "missing pubspec.yaml";
    file = new File(Path.join(directory.path, "bin", "plugin.dart"));
    if (!await file.exists()) {
      file = new File(Path.join(directory.path, "bin", "main.dart"));
      if (!await file.exists())
        throw "missing bin/plugin.dart or bin/main.dart";
    }
  }

  Future<String> _getPluginName(Directory directory) async {
    var file = new File(Path.join(directory.path, "pubspec.yaml"));
    var pubspec = Yaml.loadYaml(await file.readAsString());
    return pubspec["name"] as String;
  }

  void _subscribeControlChannels(Plugin plugin) {
    void callback(String channel, Map<String, dynamic> payload) {
      switch (channel) {
        case aliases.channelControl:
          _handleControlMessage(plugin, payload);
          return;
        case aliases.channelChatter:
          _handleChatterMessage(plugin, payload);
          return;
      }
    }

    plugin.listen(aliases.channelControl, callback);
    plugin.listen(aliases.channelChatter, callback);
  }

  void _handleControlMessage(Plugin plugin, Map<String, dynamic> payload) {
    switch (payload["status"] as String) {
      case "terminated":
        plugin.unload();
        _plugins.remove(plugin.name);
        break;
    }
  }

  void _handleChatterMessage(Plugin from, Map<String, dynamic> payload) {
    var targetPluginName = payload[aliases.chatterTargetKey]["name"] as String;
    var targetChannel = payload[aliases.chatterTargetKey]["channel"] as String;
    var targetPlugin = _plugins[targetPluginName];
    if (targetPlugin == null || targetChannel == null) return;
    payload[aliases.chatterSenderKey] = from.name;
    targetPlugin.send(targetChannel, payload);
  }
}
