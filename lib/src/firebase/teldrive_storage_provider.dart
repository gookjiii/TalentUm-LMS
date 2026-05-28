import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_provider.dart';

class TeldriveStorageProvider implements StorageProvider {
  TeldriveStorageProvider({
    required this.baseUrl,
    required this.apiKey,
    required this.channelId,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           headers: {'Authorization': 'Bearer $apiKey'},
         ),
       );

  final String baseUrl;
  final String apiKey;
  final int channelId;
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    final fileName = path.split('/').last;
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileSize = await file.length();

    // Step 1: Upload (Supporting progress via Dio)
    final response = await _dio.post(
      '/api/uploads/$uploadId',
      data: file.openRead(),
      queryParameters: {
        'fileName': fileName,
        'partNo': 1,
        'channelId': channelId,
      },
      options: Options(
        headers: {
          'Content-Length': fileSize,
          'Content-Type': 'application/octet-stream',
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    final messageId = response.data as int;

    // Step 2: Finalize
    final finalizeResponse = await _dio.post(
      '/api/files',
      data: {
        'name': fileName,
        'mimeType': _getMimeType(fileName),
        'type': 'file',
        'path': '/school_world',
        'size': fileSize,
        'parts': [
          {'id': messageId, 'salt': ''},
        ],
        'channelId': channelId,
      },
    );

    final fileData = finalizeResponse.data as Map<String, dynamic>;
    final fileId = fileData['id'] as String;

    return {
      'url': '$baseUrl/api/files/$fileId/content',
      'provider': 'teldrive',
      'fileId': fileId,
      'name': fileName,
      'mimeType': _getMimeType(fileName),
      'size': fileSize,
    };
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    final fileName = path.split('/').last;
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

    final response = await _dio.post(
      '/api/uploads/$uploadId',
      data: Stream.fromIterable([bytes]),
      queryParameters: {
        'fileName': fileName,
        'partNo': 1,
        'channelId': channelId,
      },
      options: Options(
        headers: {
          'Content-Length': bytes.length,
          'Content-Type': 'application/octet-stream',
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    final messageId = response.data as int;

    final finalizeResponse = await _dio.post(
      '/api/files',
      data: {
        'name': fileName,
        'mimeType': _getMimeType(fileName),
        'type': 'file',
        'path': '/school_world',
        'size': bytes.length,
        'parts': [
          {'id': messageId, 'salt': ''},
        ],
        'channelId': channelId,
      },
    );

    final fileData = finalizeResponse.data as Map<String, dynamic>;
    final fileId = fileData['id'] as String;

    return {
      'url': '$baseUrl/api/files/$fileId/content',
      'provider': 'teldrive',
      'fileId': fileId,
      'name': fileName,
      'mimeType': _getMimeType(fileName),
      'size': bytes.length,
    };
  }

  @override
  Future<void> deleteFile(String path) async {
    // Teldrive delete API usually uses fileId or path
    debugPrint('Teldrive delete not fully implemented: $path');
  }

  String _getMimeType(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg'))
      return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.gif')) return 'image/gif';
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
