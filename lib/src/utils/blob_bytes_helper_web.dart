import 'dart:async';
// This file is selected only by the conditional web export below.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> getBlobBytes(String blobUrl) async {
  final xhr = html.HttpRequest();
  xhr.open('GET', blobUrl);
  xhr.responseType = 'arraybuffer';
  final completer = Completer<Uint8List>();

  xhr.onLoad.listen((e) {
    if (xhr.status == 200 || xhr.status == 0) {
      final buffer = xhr.response as ByteBuffer;
      completer.complete(Uint8List.view(buffer));
    } else {
      completer.completeError('Failed to load blob (${xhr.status})');
    }
  });

  xhr.onError.listen((e) {
    completer.completeError('Error reading blob URL');
  });

  xhr.send();
  return completer.future;
}
