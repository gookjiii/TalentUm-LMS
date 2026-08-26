import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/firebase/storage_provider.dart';

class _RecordingStorageProvider implements StorageProvider {
  _RecordingStorageProvider(this.name);

  final String name;
  int uploads = 0;
  final List<String> deletions = [];

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    uploads++;
    return {'url': '$name://$path', 'provider': name};
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    uploads++;
    return {'url': '$name://$path', 'provider': name};
  }

  @override
  Future<void> deleteFile(String path) async {
    deletions.add(path);
  }
}

void main() {
  group('LargeFileStorageProvider', () {
    late _RecordingStorageProvider firebase;
    late _RecordingStorageProvider drive;
    late LargeFileStorageProvider provider;

    setUp(() {
      firebase = _RecordingStorageProvider('firebase');
      drive = _RecordingStorageProvider('google_drive');
      provider = LargeFileStorageProvider(
        standardProvider: firebase,
        largeFileProvider: drive,
        thresholdBytes: 10,
      );
    });

    test('uses Firebase below the configured threshold', () async {
      final result = await provider.uploadFileWeb('small.pdf', Uint8List(9));

      expect(result['provider'], 'firebase');
      expect(firebase.uploads, 1);
      expect(drive.uploads, 0);
    });

    test('uses Google Drive at the configured threshold', () async {
      final result = await provider.uploadFileWeb('large.pdf', Uint8List(10));

      expect(result['provider'], 'google_drive');
      expect(firebase.uploads, 0);
      expect(drive.uploads, 1);
    });

    test('routes Drive URL deletion to Google Drive', () async {
      const url = 'https://drive.google.com/file/d/file-id/view';
      await provider.deleteFile(url);

      expect(drive.deletions, [url]);
      expect(firebase.deletions, isEmpty);
    });

    test('routes Firebase URL deletion to Firebase Storage', () async {
      const url = 'https://firebasestorage.googleapis.com/v0/b/bucket/o/file';
      await provider.deleteFile(url);

      expect(firebase.deletions, [url]);
      expect(drive.deletions, isEmpty);
    });
  });
}
