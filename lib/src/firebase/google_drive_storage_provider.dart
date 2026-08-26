import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'storage_provider.dart';

class GoogleDriveStorageProvider implements StorageProvider {
  GoogleDriveStorageProvider({required this.backendBaseUrl, Dio? dio})
    : _dio = dio ?? Dio();

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
        'path': path,
      },
      options: await _authorizedOptions(),
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

    final driveFileId = await _uploadResumable(
      uploadUrl: uploadUrl,
      totalSize: length,
      mimeType: mimeType,
      chunkData: (start, end) => file.openRead(start, end),
      includeContentLength: true,
      onProgress: onProgress,
    );

    // Step 3: verify ownership/metadata and finalize the Firestore record.
    final completeResponse = await _dio.post(
      '$backendBaseUrl/api/upload/complete',
      data: {'id': recordId, 'driveFileId': driveFileId},
      options: await _authorizedOptions(),
    );

    if (completeResponse.statusCode != 200) {
      throw Exception(
        'Failed to finalize Google Drive upload: '
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
        'path': path,
      },
      options: await _authorizedOptions(),
    );

    if (initiateResponse.statusCode != 200) {
      throw Exception(
        'Failed to initiate resumable upload session on backend: ${initiateResponse.statusCode}',
      );
    }

    final data = initiateResponse.data as Map<String, dynamic>;
    final String uploadUrl = data['uploadUrl'] as String;
    final String recordId = data['id'].toString();

    final driveFileId = await _uploadResumable(
      uploadUrl: uploadUrl,
      totalSize: length,
      mimeType: mimeType,
      chunkData: (start, end) => bytes.sublist(start, end),
      includeContentLength: false,
      onProgress: onProgress,
    );

    // Step 3: verify ownership/metadata and finalize the Firestore record.
    final completeResponse = await _dio.post(
      '$backendBaseUrl/api/upload/complete',
      data: {'id': recordId, 'driveFileId': driveFileId},
      options: await _authorizedOptions(),
    );

    if (completeResponse.statusCode != 200) {
      throw Exception(
        'Failed to finalize Google Drive upload: ${completeResponse.statusCode}',
      );
    }

    final completeData = completeResponse.data as Map<String, dynamic>;
    final fileObj = (completeData['file'] as Map<String, dynamic>?) ?? {};
    final webViewLink = fileObj['webViewLink'] as String? ?? '';
    final webContentLink = fileObj['webContentLink'] as String? ?? '';
    final fallbackUrl = 'https://drive.google.com/uc?id=$driveFileId&export=download';
    final finalUrl = webContentLink.isNotEmpty ? webContentLink : (webViewLink.isNotEmpty ? webViewLink : fallbackUrl);

    return {
      'url': finalUrl,
      'provider': 'google_drive',
      'path': path,
      'driveFileId': driveFileId,
    };
  }

  Future<String> _uploadResumable({
    required String uploadUrl,
    required int totalSize,
    required String mimeType,
    required Object Function(int start, int end) chunkData,
    required bool includeContentLength,
    StorageProgressCallback? onProgress,
  }) async {
    const chunkSize = 2 * 1024 * 1024; // 2 MB (Must be a multiple of 256 KiB and < Vercel 4.5MB limit).
    var start = 0;

    while (start < totalSize) {
      final end = (start + chunkSize < totalSize)
          ? start + chunkSize
          : totalSize;
      final rangeValue = 'bytes $start-${end - 1}/$totalSize';
      final headers = <String, dynamic>{
        'Content-Type': mimeType,
        'Content-Range': rangeValue,
        'x-upload-content-range': rangeValue,
      };
      if (includeContentLength) headers['Content-Length'] = end - start;

      final targetUrl =
          kIsWeb ? '$backendBaseUrl/api/upload/initiate' : uploadUrl;
      if (kIsWeb) {
        headers['x-upload-url'] = uploadUrl;
        final authHeaders = (await _authorizedOptions()).headers;
        if (authHeaders != null) headers.addAll(authHeaders);
      }

      Response<dynamic>? response;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          response = await _dio.put(
            targetUrl,
            data: chunkData(start, end),
            options: Options(
              headers: headers,
              validateStatus: (status) =>
                  status == 200 || status == 201 || status == 308,
            ),
            onSendProgress: (sent, total) {
              if (onProgress != null && totalSize > 0) {
                onProgress((start + sent) / totalSize);
              }
            },
          );
          break;
        } on DioException catch (error) {
          final retryable = error.response == null ||
              (error.response!.statusCode ?? 0) >= 500;
          if (!retryable || attempt == 3) rethrow;
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      final status = response?.statusCode;
      if (status == 200 || status == 201) {
        final rawData = response!.data;
        final Map<String, dynamic> data;
        if (rawData is Map) {
          data = Map<String, dynamic>.from(rawData);
        } else if (rawData is String) {
          data = Map<String, dynamic>.from(jsonDecode(rawData) as Map);
        } else {
          throw Exception('Unexpected response format from Google Drive: $rawData');
        }
        final id = data['id']?.toString();
        if (id == null || id.isEmpty) {
          throw Exception('Google Drive completed upload without a file ID');
        }
        onProgress?.call(1);
        return id;
      }
      if (status != 308) {
        throw Exception('Google Drive chunk upload failed: $status');
      }

      final receivedRange = response!.headers.value('range');
      final receivedEnd = receivedRange == null
          ? null
          : int.tryParse(receivedRange.split('-').last);
      start = receivedEnd == null ? end : receivedEnd + 1;
    }

    throw Exception('Google Drive upload ended without completion metadata');
  }

  @override
  Future<void> deleteFile(String pathOrUrl) async {
    final driveFileId = _extractDriveFileId(pathOrUrl);
    if (driveFileId == null) {
      throw ArgumentError('Could not parse Google Drive file ID');
    }
    await _dio.post(
      '$backendBaseUrl/api/upload/delete_drive',
      data: {'driveFileId': driveFileId},
      options: await _authorizedOptions(),
    );
    debugPrint('Google Drive file deleted successfully: $driveFileId');
  }

  String? _extractDriveFileId(String value) {
    final uri = Uri.tryParse(value);
    final queryId = uri?.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final patterns = [
      RegExp(
        r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'docs\.google\.com/(?:document|spreadsheets|presentation)/d/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(value);
      if (match != null) return match.group(1);
    }
    return null;
  }

  Future<Options> _authorizedOptions() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        'A signed-in Firebase user is required for this operation.',
      );
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'epub':
        return 'application/epub+zip';
      default:
        return 'application/octet-stream';
    }
  }
}
