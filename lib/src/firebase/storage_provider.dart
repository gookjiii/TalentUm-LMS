import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'teldrive_storage_provider.dart';
import 'google_drive_storage_provider.dart';

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

  SettableMetadata _buildMetadata(String path) {
    final ext = path.split('.').last.toLowerCase();
    String contentType;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
      case 'pdf':
        contentType = 'application/pdf';
        break;
      default:
        contentType = 'application/octet-stream';
    }
    return SettableMetadata(contentType: contentType);
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final task = ref.putFile(file, _buildMetadata(path));
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
    final task = ref.putData(bytes, _buildMetadata(path));
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
  Future<void> deleteFile(String pathOrUrl) async {
    final ref =
        pathOrUrl.startsWith('gs://') ||
            pathOrUrl.startsWith('http://') ||
            pathOrUrl.startsWith('https://')
        ? _storage.refFromURL(pathOrUrl)
        : _storage.ref().child(pathOrUrl);
    await ref.delete();
  }
}

/// Stores small files in Firebase Storage and routes large files to Google
/// Drive. Existing URLs are deleted through the provider that owns them.
class LargeFileStorageProvider implements StorageProvider {
  LargeFileStorageProvider({
    required this.standardProvider,
    required this.largeFileProvider,
    required this.thresholdBytes,
  });

  final StorageProvider standardProvider;
  final StorageProvider largeFileProvider;
  final int thresholdBytes;

  @override
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    StorageProgressCallback? onProgress,
  }) async {
    final useLarge = await file.length() >= thresholdBytes;
    if (useLarge) {
      try {
        return await largeFileProvider.uploadFile(
          path,
          file,
          onProgress: onProgress,
        );
      } catch (e) {
        debugPrint(
          'Large file provider error, falling back to standard provider: $e',
        );
        return standardProvider.uploadFile(path, file, onProgress: onProgress);
      }
    }
    return standardProvider.uploadFile(path, file, onProgress: onProgress);
  }

  @override
  Future<Map<String, dynamic>> uploadFileWeb(
    String path,
    Uint8List bytes, {
    StorageProgressCallback? onProgress,
  }) async {
    final useLarge = bytes.length >= thresholdBytes;
    if (useLarge) {
      try {
        return await largeFileProvider.uploadFileWeb(
          path,
          bytes,
          onProgress: onProgress,
        );
      } catch (e) {
        debugPrint(
          'Large file provider web error, falling back to standard provider: $e',
        );
        return standardProvider.uploadFileWeb(
          path,
          bytes,
          onProgress: onProgress,
        );
      }
    }
    return standardProvider.uploadFileWeb(path, bytes, onProgress: onProgress);
  }

  @override
  Future<void> deleteFile(String pathOrUrl) {
    final isDriveUrl =
        pathOrUrl.contains('drive.google.com') ||
        pathOrUrl.contains('docs.google.com') ||
        pathOrUrl.contains('drive.usercontent.google.com');
    return (isDriveUrl ? largeFileProvider : standardProvider).deleteFile(
      pathOrUrl,
    );
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
    defaultValue: 'dp50nlimq',
  );
  static const configuredUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'schoolWorld',
  );
  static const configuredTeldriveBaseUrl = String.fromEnvironment(
    'TELDRIVE_BASE_URL',
  );
  static const configuredTeldriveApiKey = String.fromEnvironment(
    'TELDRIVE_API_KEY',
  );
  static const configuredTeldriveChannelId = String.fromEnvironment(
    'TELDRIVE_CHANNEL_ID',
  );
  static const configuredGoogleDriveProxyUrl = String.fromEnvironment(
    'GOOGLE_DRIVE_PROXY_URL',
    defaultValue: 'https://vercel-talentum-backend.vercel.app',
  );
  static const configuredLargeFileThresholdMb = int.fromEnvironment(
    'GOOGLE_DRIVE_LARGE_FILE_THRESHOLD_MB',
    defaultValue: 0,
  );

  static bool get isConfigured =>
      configuredCloudName.isNotEmpty && configuredUploadPreset.isNotEmpty;

  static bool get isTeldriveConfigured =>
      configuredTeldriveBaseUrl.isNotEmpty &&
      configuredTeldriveApiKey.isNotEmpty &&
      configuredTeldriveChannelId.isNotEmpty;

  static bool get isGoogleDriveConfigured =>
      configuredGoogleDriveProxyUrl.isNotEmpty;

  static StorageProvider fromEnvironmentOrFirebase() {
    if (isConfigured) {
      return CloudinaryStorageProvider(
        cloudName: configuredCloudName,
        uploadPreset: configuredUploadPreset,
      );
    }
    if (isTeldriveConfigured) {
      final channelId = int.tryParse(configuredTeldriveChannelId) ?? 0;
      return TeldriveStorageProvider(
        baseUrl: configuredTeldriveBaseUrl,
        apiKey: configuredTeldriveApiKey,
        channelId: channelId,
      );
    }
    if (isGoogleDriveConfigured) {
      return GoogleDriveStorageProvider(
        backendBaseUrl: configuredGoogleDriveProxyUrl,
      );
    }
    return FirebaseStorageProvider();
  }

  /// Storage provider for chat: always Cloudinary (images/videos).
  /// Falls back to Firebase if Cloudinary is not configured.
  static StorageProvider chatProvider() {
    if (isConfigured) {
      return CloudinaryStorageProvider(
        cloudName: configuredCloudName,
        uploadPreset: configuredUploadPreset,
      );
    }
    return FirebaseStorageProvider();
  }

  /// Profile avatars stay on the image provider and are not routed through
  /// the Google Drive threshold used for large attachments.
  static StorageProvider avatarProvider() {
    if (isConfigured) {
      return CloudinaryStorageProvider(
        cloudName: configuredCloudName,
        uploadPreset: configuredUploadPreset,
      );
    }
    return FirebaseStorageProvider();
  }

  /// Storage provider for chat attachments.
  ///
  /// Chat media keeps using the configured chat provider for normal-sized
  /// uploads, while files at or above the configured threshold are sent to
  /// Google Drive. The standard provider remains an error fallback so a
  /// temporary Drive outage does not block sending a message.
  static StorageProvider chatAttachmentProvider() {
    final standardProvider = chatProvider();
    if (!isGoogleDriveConfigured) return standardProvider;

    return LargeFileStorageProvider(
      standardProvider: standardProvider,
      largeFileProvider: GoogleDriveStorageProvider(
        backendBaseUrl: configuredGoogleDriveProxyUrl,
      ),
      thresholdBytes: configuredLargeFileThresholdMb * 1024 * 1024,
    );
  }

  /// All document, homework, assignment, and library files use Google Drive directly,
  /// bypassing Firebase Storage limits, with Firebase Storage as an error fallback.
  static StorageProvider libraryProvider() {
    if (isGoogleDriveConfigured) {
      return LargeFileStorageProvider(
        standardProvider: FirebaseStorageProvider(),
        largeFileProvider: GoogleDriveStorageProvider(
          backendBaseUrl: configuredGoogleDriveProxyUrl,
        ),
        thresholdBytes: configuredLargeFileThresholdMb * 1024 * 1024,
      );
    }
    return FirebaseStorageProvider();
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
    const chunkSize = 10 * 1024 * 1024; // 10 MB per chunk

    Response<dynamic>? lastResponse;
    int bytesUploaded = 0;

    for (int start = 0; start < totalSize; start += chunkSize) {
      final end = (start + chunkSize < totalSize)
          ? start + chunkSize
          : totalSize;
      final chunkLength = end - start;

      var multipartFile = await getChunk(start, end);

      try {
        const maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
            break; // success
          } on DioException catch (e) {
            // Only retry on network-layer errors (no HTTP response from server)
            if (e.response != null || attempt == maxRetries) {
              throw Exception(
                'Cloudinary error: ${e.response?.statusCode} - ${e.response?.data}',
              );
            }
            // Exponential backoff: 500ms, 1s, 2s
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            // Re-create the chunk for retry since the stream may be consumed
            multipartFile = await getChunk(start, end);
          }
        }
      } catch (e) {
        rethrow;
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
  Future<void> deleteFile(String pathOrUrl) async {
    // Attempt to extract the public ID from the URL.
    // Cloudinary URLs usually look like: .../upload/v12345/folder/file.ext
    try {
      if (!pathOrUrl.contains('cloudinary.com')) return;
      final uri = Uri.parse(pathOrUrl);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 2 < segments.length) {
        // public_id is everything after the version string (v123...), minus the extension
        final publicIdWithExt = segments.sublist(uploadIndex + 2).join('/');
        final publicId = publicIdWithExt.contains('.')
            ? publicIdWithExt.substring(0, publicIdWithExt.lastIndexOf('.'))
            : publicIdWithExt;

        final resourceType = pathOrUrl.contains('/video/') ? 'video' : 'image';

        const proxyUrl = String.fromEnvironment('GOOGLE_DRIVE_PROXY_URL');

        if (proxyUrl.isNotEmpty) {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token == null || token.isEmpty) return;
          await _dio.post(
            '$proxyUrl/api/upload/delete_cloudinary',
            data: {'publicId': publicId, 'resourceType': resourceType},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          debugPrint('Cloudinary file deleted: $publicId');
        }
      }
    } catch (e) {
      debugPrint('Cloudinary delete error: $e');
    }
  }
}
