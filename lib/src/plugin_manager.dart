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
  static final Duration _loadTimeout = new Duration(milliseconds: 5000);

  final Map<String, Plugin> _plugins = new Map();

  List<Plugin> get plugins => new List.unmodifiable(_plugins.values);

  Stream<Plugin> loadAll(Directory directory,
      [Map<String, List<String>> pluginArgs = null]) {
    pluginArgs = pluginArgs ?? {};
    return directory
        .list()
        .map((entity) => entity is! Directory ? null : entity as Directory)
        .asyncMap((target) {
      return _validateDirectory(target)
          .then((_) => _getPluginName(target))
          .then((name) => _load(target, name, pluginArgs[name]));
    });
  }

  Future<Plugin> load(Directory directory,
      {String name = null, List<String> args = null}) {
    return _validateDirectory(directory).then((_) {
      var completer = new Completer<String>();
      name != null
          ? completer.complete(name)
          : _getPluginName(directory).then((name) {
              completer.complete(name);
              return name;
            });
      return completer.future;
    }).then((name) => _load(directory, name, args));
  }

  Future<Plugin> _load(Directory directory, String name, List<String> args) {
    if (_plugins.containsKey(name)) {
      return new Future.error(
          "Duplicate plugin load detected. Plugin: ${name}, ${directory}");
    }

    var receiver = new ReceivePort();
    var completer = new Completer<Plugin>();
    return _isolate(
            directory, args ?? [], {"name": name, "port": receiver.sendPort})
        .then((Isolate isolate) {
      isolate.addOnExitListener(receiver.sendPort, response: {
        "channel": aliases.channelControl,
        "payload": {"status": "terminated"}
      });
      var subscription = receiver.listen(null);
      subscription.onData((SendPort contact) {
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
      isolate.resume(isolate.pauseCapability);
      return completer.future;
    }, onError: completer.completeError).timeout(_loadTimeout, onTimeout: () {
      throw "Failed to initialise Plugin: ${name}, Timeout: ${_loadTimeout.inMilliseconds}ms";
    });
  }

  Future<Isolate> _isolate(
      Directory directory, List<String> args, var initialMessage) {
    var entryFile = new File(Path.join(directory.path, "bin", "main.dart"));
    return Isolate.spawnUri(entryFile.absolute.uri, args, initialMessage,
        paused: true);
  }

  Future _validateDirectory(Directory directory) {
    return new File(Path.join(directory.path, "pubspec.yaml"))
        .exists()
        .then((pubspecExists) {
      if (!pubspecExists) {
        throw "Could not locate plugin pubspec.yaml in ${directory}";
      }
      return new File(Path.join(directory.path, "bin", "main.dart"))
          .exists()
          .then((entryPointExists) {
        if (!entryPointExists)
          throw "Could not locate plugin entry point in ${directory}";
      });
    });
  }

  Future<String> _getPluginName(Directory directory) {
    var file = new File(Path.join(directory.path, "pubspec.yaml"));
    return file.readAsString().then((yaml) {
      return Yaml.loadYaml(yaml)["name"];
    });
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
