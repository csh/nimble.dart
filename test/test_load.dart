import 'dart:async';
import 'dart:io';

import 'package:nimble/loader.dart';
import 'package:test/test.dart';

void main() {
  test('PluginManager.load() correctly isolates and loads a plugin', () async {
    var directory = new Directory("test-plugin");
    var manager = new PluginManager();
    var plugin = await manager.load(directory);
    var completer = new Completer<String>();
    plugin.listen("test", (channel, data) {
      completer.complete(data["message"]);
    });
    expect(completer.future, completion(equals("Hello World")));
    plugin.send("nimble:control", {"command": "terminate"});
  });
}
 