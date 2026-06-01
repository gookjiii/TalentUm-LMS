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

    // Auto-compress images
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      try {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null && image.width > 1200) {
          final resized = img.copyResize(image, width: 1200);
          final compressedBytes = Uint8List.fromList(
            img.encodeJpg(resized, quality: 85),
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

    final provider = CloudinaryStorageProvider.chatProvider();
    final result = await provider.uploadFile(path, fileToUpload);
    return {'url': result['url'], 'path': path};
  }

  Future<Map<String, dynamic>?> uploadFileWeb(
    String path,
    Uint8List bytes,
  ) async {
    Uint8List finalBytes = bytes;

    // Web compression
    try {
      final image = img.decodeImage(bytes);
      if (image != null && image.width > 1200) {
        final resized = img.copyResize(image, width: 1200);
        finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      }
    } catch (e) {
      debugPrint('Web image compression error: $e');
    }

    final provider = CloudinaryStorageProvider.chatProvider();
    final result = await provider.uploadFileWeb(path, finalBytes);
    return {'url': result['url'], 'path': path};
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
