import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

abstract class StorageProvider {
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  });
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  });
  Future<void> deleteFile(String path);
}

typedef StorageProgressCallback = void Function(double progress);

class FirebaseStorageProvider implements StorageProvider {
  FirebaseStorageProvider({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final task = ref.putFile(file);
    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        onProgress(progress);
      });
    }
    await task;
    final url = await ref.getDownloadURL();
    return {'url': url, 'provider': 'firebase', 'path': path};
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final task = ref.putData(bytes);
    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        onProgress(progress);
      });
    }
    await task;
    final url = await ref.getDownloadURL();
    return {'url': url, 'provider': 'firebase', 'path': path};
  }

  @override
  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}

class CloudinaryStorageProvider implements StorageProvider {
  CloudinaryStorageProvider({
    required String cloudName,
    required String uploadPreset,
    Dio? dio,
  }) : _cloudName = cloudName,
       _uploadPreset = uploadPreset,
       _dio = dio ?? Dio();

  final String _cloudName;
  final String _uploadPreset;
  final Dio _dio;

  static const configuredCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const configuredUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static bool get isConfigured =>
      configuredCloudName.isNotEmpty && configuredUploadPreset.isNotEmpty;

  static StorageProvider fromEnvironmentOrFirebase() {
    if (!isConfigured) return FirebaseStorageProvider();
    return CloudinaryStorageProvider(
      cloudName: configuredCloudName,
      uploadPreset: configuredUploadPreset,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    final length = await file.length();
    final response = await _uploadChunked(
      path: path,
      totalSize: length,
      getChunk: (start, end) async {
        return MultipartFile.fromStream(
          () => file.openRead(start, end),
          end - start,
          filename: _filename(path),
        );
      },
      onProgress: onProgress,
    );
    return _toResult(path, response.data);
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    final response = await _uploadChunked(
      path: path,
      totalSize: bytes.length,
      getChunk: (start, end) async {
        return MultipartFile.fromBytes(
          bytes.sublist(start, end),
          filename: _filename(path),
        );
      },
      onProgress: onProgress,
    );
    return _toResult(path, response.data);
  }

  Future<Response<dynamic>> _uploadChunked({
    required String path,
    required int totalSize,
    required Future<MultipartFile> Function(int start, int end) getChunk,
    StorageProgressCallback? onProgress,
  }) async {
    final uploadUrl = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/auto/upload',
    ).toString();
    final folder = path.split('/').take(2).join('/');
    
    // Fallback to simple upload if file is empty
    if (totalSize == 0) {
      return _dio.post(
        uploadUrl,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes([], filename: _filename(path)),
          'upload_preset': _uploadPreset,
          'folder': folder,
        }),
      );
    }

    final uniqueUploadId = DateTime.now().millisecondsSinceEpoch.toString();
    final chunkSize = 10 * 1024 * 1024; // 10 MB per chunk
    
    Response<dynamic>? lastResponse;
    int bytesUploaded = 0;

    for (int start = 0; start < totalSize; start += chunkSize) {
      final end = (start + chunkSize < totalSize) ? start + chunkSize : totalSize;
      final chunkLength = end - start;
      
      final multipartFile = await getChunk(start, end);

      try {
        lastResponse = await _dio.post(
          uploadUrl,
          data: FormData.fromMap({
            'file': multipartFile,
            'upload_preset': _uploadPreset,
            'folder': folder,
          }),
          options: Options(
            headers: {
              'X-Unique-Upload-Id': uniqueUploadId,
              'Content-Range': 'bytes $start-${end - 1}/$totalSize',
            },
          ),
          onSendProgress: (sent, total) {
            if (onProgress != null && chunkLength > 0) {
               onProgress((bytesUploaded + sent) / totalSize);
            }
          },
        );
      } on DioException catch (e) {
        throw Exception('Cloudinary error: ${e.response?.statusCode} - ${e.response?.data}');
      }
      
      bytesUploaded += chunkLength;
    }
    
    return lastResponse!;
  }

  Map<String, dynamic> _toResult(String path, dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return {
      'url': map['secure_url']?.toString() ?? map['url']?.toString() ?? '',
      'provider': 'cloudinary',
      'path': path,
      'publicId': map['public_id']?.toString(),
      'resourceType': map['resource_type']?.toString(),
      'format': map['format']?.toString(),
      'bytes': map['bytes'],
    };
  }

  String _filename(String path) => path.split('/').last;

  @override
  Future<void> deleteFile(String path) async {
    debugPrint('Cloudinary delete requires a signed backend call: $path');
  }
}

class MockStorageProvider implements StorageProvider {
  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (onProgress != null) onProgress(i / 10);
    }
    return {
      'url':
          'https://via.placeholder.com/600x400.png?text=Mock+Teldrive+Upload',
      'provider': 'mock',
      'fileId': 'mock-id-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (onProgress != null) onProgress(i / 10);
    }
    return {
      'url':
          'https://via.placeholder.com/600x400.png?text=Mock+Teldrive+Web+Upload',
      'provider': 'mock',
      'fileId': 'mock-id-web-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  @override
  Future<void> deleteFile(String path) async {
    debugPrint('Mock delete: $path');
  }
}
