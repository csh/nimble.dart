import 'dart:async';
import 'package:nimble/loader.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  group('PluginManager', () {
    test('load()', () {
      var directory = getPluginDirectory("01-echo");
      logger.info("Loading plugin from ${directory.absolute}");
      var manager = new PluginManager();
      return manager.load(directory).then((echo) {
        logger.info("Plugin load completed");
        expect(echo, isPluginLoaded(name: "echo"));
        logger.info("Plugin will terminate");
        echo.unload();
        logger.info("Plugin terminated? ${echo.isLoaded == false}");
        expect(echo.isLoaded, isFalse,
            reason: "isolate should have terminated");
      });
    });

    test('loadAll()', () {
      logger.info("Loading plugins from ${getPluginContainer().absolute}");
      var manager = new PluginManager();
      var stream = manager.loadAll(getPluginContainer());

      var completer = new Completer();
      stream.listen((plugin) {
        expect(plugin, isPluginLoaded());
        logger.info("Loaded ${plugin}");
        completer.complete();
      }, onDone: () {
        manager.plugins.forEach((plugin) {
          plugin.unload();
          logger.info("Unloaded ${plugin}");
        });
      });
      return completer.future;
    });
  });
}
