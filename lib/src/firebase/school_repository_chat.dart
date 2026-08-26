import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:school_world/src/firebase/storage_provider.dart';
import 'safe_firestore.dart';

mixin SchoolRepositoryChat {
  FirebaseFirestore get firestore;
  FirebaseStorage get storage;

  Future<void> markMessageAsSeen(String roomId, String messageId) async {
    final uid = this.uid;
    if (uid == null) return;

    // Defer execution to next tick to avoid synchronous Firestore JS SDK stream conflicts during render/visibility callbacks
    Future.delayed(Duration.zero, () async {
      try {
        await firestore
            .collection('rooms')
            .doc(roomId)
            .collection('messages')
            .doc(messageId)
            .update({
              'metadata.seenBy': FieldValue.arrayUnion([uid]),
            });
      } catch (e) {
        debugPrint('Error marking message as seen: $e');
      }
    });
  }

  Future<Map<String, dynamic>?> uploadFile(String path, File file) async {
    File fileToUpload = file;

    final ext = path.split('.').last.toLowerCase();
    final isMedia = [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'mp4',
      'mov',
      'webm',
      'avi',
      'mkv',
      'm4a',
      'mp3',
      'aac',
      'wav',
      'ogg',
      'opus',
      'caf',
      'flac',
    ].contains(ext);

    // Downscale only genuinely oversized images. Chat images have already been
    // prepared by the composer, so re-encoding them here would blur text and
    // handwriting in the full-screen preview.
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      try {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null && (image.width > 2560 || image.height > 2560)) {
          final resized = img.copyResize(
            image,
            width: image.width >= image.height ? 2560 : null,
            height: image.height > image.width ? 2560 : null,
            interpolation: img.Interpolation.cubic,
          );
          final compressedBytes = Uint8List.fromList(
            img.encodeJpg(resized, quality: 92),
          );
          final tempDir = file.parent.path;
          final tempFile = File(
            '$tempDir/temp_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tempFile.writeAsBytes(compressedBytes);
          fileToUpload = tempFile;
        }
      } catch (e) {
        debugPrint('Image compression error: $e');
      }
    }

    final provider = isMedia
        ? CloudinaryStorageProvider.chatAttachmentProvider()
        : CloudinaryStorageProvider.libraryProvider();
    final result = await provider.uploadFile(path, fileToUpload);
    return {
      'url': result['url'],
      'path': path,
      if (result['provider'] != null) 'provider': result['provider'],
      if (result['driveFileId'] != null) 'driveFileId': result['driveFileId'],
    };
  }

  Future<Map<String, dynamic>?> uploadFileWeb(
    String path,
    Uint8List bytes,
  ) async {
    Uint8List finalBytes = bytes;

    final ext = path.split('.').last.toLowerCase();
    final isMedia = [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'mp4',
      'mov',
      'webm',
      'avi',
      'mkv',
      'm4a',
      'mp3',
      'aac',
      'wav',
      'ogg',
      'opus',
      'caf',
      'flac',
    ].contains(ext);

    // Preserve the already-prepared chat image whenever it is within the
    // maximum dimension. This avoids the former double JPEG compression.
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      try {
        final image = img.decodeImage(bytes);
        if (image != null && (image.width > 2560 || image.height > 2560)) {
          final resized = img.copyResize(
            image,
            width: image.width >= image.height ? 2560 : null,
            height: image.height > image.width ? 2560 : null,
            interpolation: img.Interpolation.cubic,
          );
          finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 92));
        }
      } catch (e) {
        debugPrint('Web image compression error: $e');
      }
    }

    final provider = isMedia
        ? CloudinaryStorageProvider.chatAttachmentProvider()
        : CloudinaryStorageProvider.libraryProvider();
    final result = await provider.uploadFileWeb(path, finalBytes);
    return {
      'url': result['url'],
      'path': path,
      if (result['provider'] != null) 'provider': result['provider'],
      if (result['driveFileId'] != null) 'driveFileId': result['driveFileId'],
    };
  }

  String? get uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> roomMediaStore(String roomId) {
    return firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .where('type', whereIn: ['image', 'video'])
        .orderBy('createdAt', descending: true)
        .safeSnapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> roomFilesStore(String roomId) {
    return firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .where('type', isEqualTo: 'file')
        .orderBy('createdAt', descending: true)
        .safeSnapshots();
  }
}
