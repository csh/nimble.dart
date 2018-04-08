import 'dart:isolate';

void main(List<String> args, SendPort sender) {
  var receiver = new ReceivePort();
  receiver.listen((data) {
    print("Plugin received message, name: ${data['name']}");
    sender.send(true);
  });
  var exchange = receiver.sendPort;
  sender.send(exchange);
}
