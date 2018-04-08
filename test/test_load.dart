import 'dart:async';
import 'dart:io';

import 'package:nimble/loader.dart';
import 'package:test/test.dart';

void main() {
  test('PluginManager.load() correctly isolates and loads a plugin', () async {
    var directory = new Directory("test-plugin");
    var manager = new PluginManager();
    var plugin = await manager.load(directory);
    var subscription = plugin.internals["subscription"] as StreamSubscription;
    var completer = new Completer<bool>();
    subscription.onData((message) {
      completer.complete(message as bool);
    });
    expect(completer.future, completion(equals(true)));
  });
}
