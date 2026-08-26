import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ILovePdfService {
  ILovePdfService({Dio? dio}) : _dio = dio ?? Dio();
  
  final Dio _dio;
  
  // The public key should be provided via flutter build --dart-define=ILOVEPDF_PUBLIC_KEY=your_key
  // For development, we can fallback to a placeholder or empty string.
  static const String _publicKey = String.fromEnvironment('ILOVEPDF_PUBLIC_KEY', defaultValue: 'project_public_aeeb94e2c6a651dd01c6b9f5016e71b4_fbpBX006fc9af1ae62478dbae7c4dd8ac1253');

  Future<Uint8List> compressPdf(Uint8List fileBytes, String fileName) async {
    if (_publicKey.isEmpty) {
      throw Exception('ILOVEPDF_PUBLIC_KEY is not configured. Cannot compress PDF on Web.');
    }

    try {
      // 1. Auth to get JWT Token
      final authRes = await _dio.post(
        'https://api.ilovepdf.com/v1/auth',
        data: {'public_key': _publicKey},
      );
      final token = authRes.data['token'] as String;

      // 2. Start a Compress Task
      final startRes = await _dio.get(
        'https://api.ilovepdf.com/v1/start/compress',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final server = startRes.data['server'] as String;
      final taskId = startRes.data['task'] as String;

      // 3. Upload File
      final formData = FormData.fromMap({
        'task': taskId,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final uploadRes = await _dio.post(
        'https://$server/v1/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final serverFilename = uploadRes.data['server_filename'] as String;

      // 4. Process Task
      await _dio.post(
        'https://$server/v1/process',
        data: {
          'task': taskId,
          'tool': 'compress',
          'compression_level': 'recommended', // extreme, recommended, less
          'files': [
            {
              'server_filename': serverFilename,
              'filename': fileName,
            }
          ]
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 5. Download Processed File
      final downloadRes = await _dio.get<List<int>>(
        'https://$server/v1/download/$taskId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(downloadRes.data!);
    } catch (e) {
      debugPrint('ILovePDF Compression Error: $e');
      throw Exception('Lỗi khi nén PDF qua iLovePDF: $e');
    }
  }
}
