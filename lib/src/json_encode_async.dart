part of json_async;

ReceivePort _jsonEncoderReceivePort = ReceivePort();

_encodeJson(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    final encoded = jsonEncode(msg[0]);
    final SendPort replyPort = msg[1];
    replyPort.send(encoded);
  });
}

SendPort _jsonEncoderSendPort;

Future _jsonEncodeAsyncOnPort(SendPort send, message) {
  final ReceivePort receivePort = ReceivePort();
  send.send([message, receivePort.sendPort]);
  return receivePort.first;
}

Future jsonEncodeAsync(Map<String, dynamic> json) async {
  if (_jsonEncoderSendPort == null) {
    try {
      await Isolate.spawn(_encodeJson, _jsonEncoderReceivePort.sendPort);
      _jsonEncoderSendPort = await _jsonEncoderReceivePort.first;
    } catch (e) {
      if (!_notifiedAboutSpawnError) {
        print('!! Spawning isolate failed, JSON is processed on main thread');
        print('!! $e');
        print('!! Flutter: https://github.com/flutter/flutter/issues/14815');
        _notifiedAboutSpawnError = true;
      }

      return jsonEncode(json);
    }
  }

  return _jsonEncodeAsyncOnPort(_jsonEncoderSendPort, json);
}
