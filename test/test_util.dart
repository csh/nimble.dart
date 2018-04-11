import 'dart:io';

import 'package:logging/logging.dart';
import 'package:nimble/loader.dart';
import 'package:path/path.dart' as Path;
import 'package:test/test.dart';

final Logger logger = _createLogger();

Logger _createLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('[${rec.loggerName}/${rec.level.name}] ${rec.time}: ${rec.message}');
  });
  return new Logger("nimble");
}


Directory getPluginContainer() {
  return new Directory(Path.join("test", "plugins"));
}

Directory getPluginDirectory(String name) {
  return new Directory(Path.join(getPluginContainer().path, name));
}

Matcher isPluginLoaded({String name = null}) {
  return new _PluginLoaded(name);
}

class _PluginLoaded extends Matcher {
  final String name;

  _PluginLoaded(this.name);

  bool matches(item, Map matchState) {
    if (item is! Plugin) return false;
    if (name != null && name != item.name) return false;
    return item.isLoaded;
  }

  Description describe(Description description) {
    return description
        .addDescriptionOf("is a named Plugin where isLoaded = true");
  }
}
