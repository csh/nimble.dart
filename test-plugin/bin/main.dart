import 'package:nimble/interface.dart';

void main(List<String> args, dynamic message) {
  PluginInterface iface = new PluginInterface(message);
  iface.send("test", {"message": "Hello World"});
}
