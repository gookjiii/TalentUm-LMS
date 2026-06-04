import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();
  const publicKey = 'project_public_aeeb94e2c6a651dd01c6b9f5016e71b4_fbpBX006fc9af1ae62478dbae7c4dd8ac1253';
  try {
    print('1. Auth...');
    final authRes = await dio.post(
      'https://api.ilovepdf.com/v1/auth',
      data: {'public_key': publicKey},
    );
    final token = authRes.data['token'] as String;
    print('Token: $token');

    print('2. Start...');
    final startRes = await dio.get(
      'https://api.ilovepdf.com/v1/start/compress',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final server = startRes.data['server'] as String;
    final taskId = startRes.data['task'] as String;
    print('Server: $server, Task: $taskId');

    final dummyPdf = "%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj 2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj 3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj xref\n0 4\n0000000000 65535 f\n0000000009 00000 n\n0000000052 00000 n\n0000000101 00000 n\ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n178\n%%EOF\n".codeUnits;

    print('3. Upload...');
    final formData = FormData.fromMap({
      'task': taskId,
      'file': MultipartFile.fromBytes(dummyPdf, filename: 'dummy.pdf'),
    });
    final uploadRes = await dio.post(
      'https://$server/v1/upload',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final serverFilename = uploadRes.data['server_filename'] as String;
    print('Uploaded: $serverFilename');

    print('4. Process...');
    await dio.post(
      'https://$server/v1/process',
      data: {
        'task': taskId,
        'tool': 'compress',
        'compression_level': 'recommended',
        'files': [
          {
            'server_filename': serverFilename,
            'filename': 'dummy.pdf',
          }
        ]
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    print('Processed!');
  } catch (e) {
    if (e is DioException) {
      print('Dio error: ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
