import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_upload_flutter_firebase/src/photo.dart';

class ImageUploadRepository {
  ImageUploadRepository({
    required this.storage,
    required this.firestore,
  });
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;

  Future<String> uploadFile(PlatformFile file) async {
    // iOS / Android only
    final result = await _upload(file);

    final imageUrl = await result.ref.getDownloadURL();
    final filename = filenameRemovingExtension(file);
    // TODO: write a cloud function that can write the thumbURL for the thumb
    // generated by the Image Resize extension
    await firestore.doc('photos/$filename').set({
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return result.ref.fullPath;
  }

  String filenameRemovingExtension(PlatformFile file) {
    if (file.extension != null) {
      final extIndex = file.name.lastIndexOf(file.extension!);
      return file.name.substring(0, extIndex - 1);
    } else {
      return file.name;
    }
  }

  UploadTask _upload(PlatformFile file) {
    final contentType = 'image/${file.extension}';
    final ref = storage.ref('photos/${file.name}');
    if (file.path != null) {
      return ref.putFile(
        File(file.path!),
        SettableMetadata(contentType: contentType),
      );
    } else if (file.bytes != null) {
      return ref.putData(
        file.bytes!,
        SettableMetadata(contentType: contentType),
      );
    } else {
      throw StateError('Both file.path and file.bytes cannot be null');
    }
  }

  // Future<String> uploadAsset(String assetName) async {
  //   final byteData = await rootBundle.load(assetName);
  //   final result = await _uploadAsset(byteData, assetName);
  //   // TODO: write to firestore etc
  // }

  // UploadTask _uploadAsset(ByteData byteData, String filename) {
  //   final bytes = byteData.buffer
  //       .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  //   final ref = storage.ref('photos/$filename');
  //   return ref.putData(
  //     bytes,
  //     SettableMetadata(contentType: 'image/jpeg'),
  //   );
  // }

  Future<void> deletePhoto(String photoId) async {
    // delete both image in Storage and data in Firestore
    await storage.ref('photos/$photoId').delete();
    //await storage.ref('thumbs/$photoId').delete();
    await firestore.doc('photos/$photoId').delete();
  }

  Query<Photo> photos() {
    final collectionRef = firestore.collection('photos').orderBy('createdAt');
    return collectionRef.withConverter<Photo>(
      fromFirestore: (doc, _) {
        final data = doc.data();
        return Photo.fromMap(data!, doc.id);
      },
      toFirestore: (doc, options) => doc.toMap(),
    );
  }
}

final imageUploadRepositoryProvider = Provider<ImageUploadRepository>((ref) {
  return ImageUploadRepository(
    storage: FirebaseStorage.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final photosProvider = Provider<Query<Photo>>((ref) {
  return ref.watch(imageUploadRepositoryProvider).photos();
});
