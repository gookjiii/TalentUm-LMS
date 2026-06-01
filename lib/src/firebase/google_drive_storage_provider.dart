import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_provider.dart';

class GoogleDriveStorageProvider implements StorageProvider {
  GoogleDriveStorageProvider({required this.backendBaseUrl}) : _dio = Dio();

  final String backendBaseUrl;
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    // On web, dart:io File streams cannot be used with XHR and direct PUT to
    // googleapis.com is CORS-blocked. Delegate to the proxy-based web path.
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return uploadFileWeb(path, bytes, onProgress: onProgress);
    }

    final fileName = path.split('/').last;
    final length = await file.length();
    final mimeType = _getMimeType(fileName);

    // Step 1: Initiate resumable session via backend proxy
    final initiateResponse = await _dio.post(
      '$backendBaseUrl/api/upload/initiate',
      data: {
        'name': fileName,
        'mimeType': mimeType,
        'size': length,
      },
    );

    if (initiateResponse.statusCode != 200) {
      throw Exception(
        'Failed to initiate resumable upload session on backend: '
        '${initiateResponse.statusCode}',
      );
    }

    final data = initiateResponse.data as Map<String, dynamic>;
    final String uploadUrl = data['uploadUrl'] as String;
    final String recordId = data['id'].toString();

    // Step 2: PUT file stream directly to the Google Drive resumable upload URL
    // (safe on native — no CORS restriction, XHR not used)
    final googleResponse = await _dio.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Length': length,
          'Content-Type': mimeType,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (googleResponse.statusCode != 200 && googleResponse.statusCode != 201) {
      throw Exception(
        'Google Drive direct upload failed: ${googleResponse.statusCode}',
      );
    }

    final googleData = googleResponse.data as Map<String, dynamic>;
    final driveFileId = googleData['id'] as String;

    // Step 3: Notify backend to finalize the record in DB
    final completeResponse = await _dio.post(
      '$backendBaseUrl/api/upload/complete',
      data: {
        'id': recordId,
        'driveFileId': driveFileId,
      },
    );

    if (completeResponse.statusCode != 200) {
      throw Exception(
        'Failed to complete upload metadata in DB: '
        '${completeResponse.statusCode}',
      );
    }

    final completeData = completeResponse.data as Map<String, dynamic>;
    final fileObj = completeData['file'] as Map<String, dynamic>;
    final webViewLink = fileObj['webViewLink'] as String? ?? '';

    return {
      'url': webViewLink,
      'provider': 'google_drive',
      'path': path,
      'driveFileId': driveFileId,
    };
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    final fileName = path.split('/').last;
    final length = bytes.length;
    final mimeType = _getMimeType(fileName);

    // Step 1: Initiate session via backend proxy
    final initiateResponse = await _dio.post(
      '$backendBaseUrl/api/upload/initiate',
      data: {
        'name': fileName,
        'mimeType': mimeType,
        'size': length,
      },
    );

    if (initiateResponse.statusCode != 200) {
      throw Exception('Failed to initiate resumable upload session on backend: ${initiateResponse.statusCode}');
    }

    final data = initiateResponse.data as Map<String, dynamic>;
    final String uploadUrl = data['uploadUrl'] as String;
    final String recordId = data['id'].toString();

    // Step 2: PUT bytes directly to Google Drive resumable upload URL
    // We send raw bytes directly as the request body. The browser automatically
    // calculates Content-Length. We omit it manually to avoid forbidden header CORS errors.
    final googleResponse = await _dio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': mimeType,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (googleResponse.statusCode != 200 && googleResponse.statusCode != 201) {
      throw Exception('Google Drive direct upload failed: ${googleResponse.statusCode}');
    }

    final googleData = googleResponse.data as Map<String, dynamic>;
    final driveFileId = googleData['id'] as String;

    // Step 3: Complete upload on backend to save metadata in DB
    final completeResponse = await _dio.post(
      '$backendBaseUrl/api/upload/complete',
      data: {
        'id': recordId,
        'driveFileId': driveFileId,
      },
    );

    if (completeResponse.statusCode != 200) {
      throw Exception('Failed to complete upload metadata in DB: ${completeResponse.statusCode}');
    }

    final completeData = completeResponse.data as Map<String, dynamic>;
    final fileObj = completeData['file'] as Map<String, dynamic>;
    final webViewLink = fileObj['webViewLink'] as String? ?? '';

    return {
      'url': webViewLink,
      'provider': 'google_drive',
      'path': path,
      'driveFileId': driveFileId,
    };
  }

  @override
  Future<void> deleteFile(String pathOrUrl) async {
    final regExp = RegExp(
      r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(pathOrUrl);
    
    if (match != null && match.groupCount >= 1) {
      final driveFileId = match.group(1);
      if (driveFileId != null) {
        try {
          const apiSecret = String.fromEnvironment('APP_API_SECRET');
          await _dio.post(
            '$backendBaseUrl/api/upload/delete_drive',
            data: {'driveFileId': driveFileId},
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiSecret',
              },
            ),
          );
          debugPrint('Google Drive file deleted successfully: $driveFileId');
        } catch (e) {
          debugPrint('Failed to delete Google Drive file: $e');
        }
      }
    } else {
      debugPrint('Could not parse Google Drive file ID from: $pathOrUrl');
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'mp4') return 'video/mp4';
    if (ext == 'mov') return 'video/quicktime';
    if (ext == 'zip') return 'application/zip';
    if (ext == 'rar') return 'application/x-rar-compressed';
    return 'application/octet-stream';
  }
}
