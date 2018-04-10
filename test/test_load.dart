import 'dart:io';

import 'package:nimble/loader.dart';
import 'package:test/test.dart';

void main() {
  test('PluginManager.load() correctly isolates and loads a plugin', () {
    var directory = new Directory("test-plugin");
    var manager = new PluginManager();
    manager.load(directory).then(expectAsync1((Plugin plugin) {
      expect(plugin.name, equals("test"));
      plugin.listen("test", expectAsync2((_, data) {
        expect(data["message"], equals("Hello World"));
        plugin.send("nimble:control", {"command": "terminate"});
      }));
    }));
  });
}
