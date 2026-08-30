import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/utils/google_drive_helper.dart';

void main() {
  group('GoogleDriveHelper', () {
    test('builds a PDF proxy URL from a Drive file id', () {
      expect(
        GoogleDriveHelper.buildPdfPreviewUrl(
          'drive-file_123',
          proxyBaseUrl: 'https://files.example.com/',
        ),
        'https://files.example.com/api/library/proxy_pdf?fileId=drive-file_123',
      );
    });

    test('returns an empty URL when the proxy input is incomplete', () {
      expect(
        GoogleDriveHelper.buildPdfPreviewUrl(
          '',
          proxyBaseUrl: 'https://files.example.com',
        ),
        isEmpty,
      );
      expect(
        GoogleDriveHelper.buildPdfPreviewUrl('drive-file', proxyBaseUrl: ''),
        isEmpty,
      );
    });
  });
}
