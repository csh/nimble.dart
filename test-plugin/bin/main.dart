import 'dart:isolate';

import 'package:nimble/interface.dart';

void main(List<String> args, SendPort sender) {
  PluginInterface iface = new PluginInterface(sender);
  iface.send("test", {"message": "Hello World"});
}
