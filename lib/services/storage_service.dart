import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadUserAvatar(String userId, File imageFile) async {
    try {
      print('🔧 Storage Bucket: ${_storage.bucket}');
      print('🔧 Storage App: ${_storage.app.name}');
      
      // 1. 檢查檔案是否存在
      if (!await imageFile.exists()) {
        throw Exception("Selected file does not exist locally: ${imageFile.path}");
      }

      // 2. 準備路徑和 Metadata
      final String ext = path.extension(imageFile.path).toLowerCase();
      final String safeExt = (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') ? ext : '.jpg';
      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}$safeExt';
      
      // 確保 userId 不包含特殊字元
      final safeUserId = userId.replaceAll(RegExp(r'[^\w-]'), '');
      final Reference ref = _storage.ref().child('users/$safeUserId/avatars/$fileName');
      
      print('🚀 Starting upload to: ${ref.fullPath}');
      print('📁 Local file size: ${await imageFile.length()} bytes');

      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(safeExt),
        customMetadata: {
          'userId': userId,
          'originalName': path.basename(imageFile.path),
        },
      );

      // 3. 執行上傳
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      
      // 增加進度監聽以便 Debug
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(1);
          print('📊 Upload progress: $progress% (${snapshot.state})');
        },
        onError: (e) {
          print('❌ Upload stream error: $e');
          print('❌ Error Code: ${(e is FirebaseException) ? e.code : 'unknown'}');
          print('❌ Error Message: ${(e is FirebaseException) ? e.message : e.toString()}');
        },
      );

      final TaskSnapshot snapshot = await uploadTask;
      
      // 4. 驗證上傳結果
      print('✅ Upload task completed with state: ${snapshot.state}');
      
      if (snapshot.state == TaskState.success) {
        // 5. 取得下載連結
        try {
          final String downloadUrl = await ref.getDownloadURL();
          print('🔗 Download URL retrieved: $downloadUrl');
          return downloadUrl;
        } catch (urlError) {
          print('❌ Failed to get download URL despite success state: $urlError');
          rethrow;
        }
      } else {
        throw Exception('Upload finished but state is not success: ${snapshot.state}');
      }
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      if (e is FirebaseException) {
         print('🔍 Firebase Error Code: ${e.code}');
         print('🔍 Firebase Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // Default to jpeg
    }
  }
}
