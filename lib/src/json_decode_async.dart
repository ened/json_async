part of json_async;

ReceivePort _jsonDecoderReceivePort = ReceivePort();

_decodeJson(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    final decoded = jsonDecode(msg[0]);
    final SendPort replyPort = msg[1];
    replyPort.send(decoded);
  });
}

SendPort _jsonDecoderSendPort;

Future _jsonDecodeAsyncOnPort(SendPort send, message) {
  final ReceivePort receivePort = ReceivePort();
  send.send([message, receivePort.sendPort]);
  return receivePort.first;
}

Future jsonDecodeAsync(String json) async {
  if (_jsonDecoderSendPort == null) {
    try {
      await Isolate.spawn(_decodeJson, _jsonDecoderReceivePort.sendPort);
      _jsonDecoderSendPort = await _jsonDecoderReceivePort.first;
    } catch (e) {
      if (!_notifiedAboutSpawnError) {
        print('!! Spawning isolate failed, JSON is processed on main thread');
        print('!! $e');
        print('!! Flutter: https://github.com/flutter/flutter/issues/14815');
        _notifiedAboutSpawnError = true;
      }

      return jsonDecode(json);
    }
  }

  return _jsonDecodeAsyncOnPort(_jsonDecoderSendPort, json);
}
