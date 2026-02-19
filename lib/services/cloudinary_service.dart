import 'dart:io';
import 'package:dio/dio.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CloudinaryService {
  final Dio _dio = Dio();

  // Upload video to Cloudinary
  Future<Map<String, dynamic>> uploadVideo(File videoFile) async {
    try {
      String fileName = videoFile.path.split('/').last;

      print('Cloudinary: Uploading video $fileName');
      print('Cloudinary: Cloud Name: ${AppConstants.cloudinaryCloudName}');
      print('Cloudinary: Preset: ${AppConstants.cloudinaryUploadPreset}');

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
        'upload_preset': AppConstants.cloudinaryUploadPreset,
      });

      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/video/upload',
        data: formData,
        onSendProgress: (sent, total) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%');
        },
      );

      if (response.statusCode == 200) {
        print('Cloudinary: Video uploaded successfully');
        return {
          'success': true,
          'url': response.data['secure_url'],
          'publicId': response.data['public_id'],
          'duration': response.data['duration'],
          'format': response.data['format'],
        };
      } else {
        print('Cloudinary: Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = 'Dio Error: ${e.response?.statusCode} - ${e.response?.data}';
      }
      print('Cloudinary: $errorMsg');
      return {'success': false, 'error': errorMsg};
    }
  }

  // Upload image (for certificates, badges, etc.)
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      print('Cloudinary: Uploading image $fileName');
      print('Cloudinary: Cloud Name: ${AppConstants.cloudinaryCloudName}');
      print('Cloudinary: Preset: ${AppConstants.cloudinaryUploadPreset}');

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'upload_preset': AppConstants.cloudinaryUploadPreset,
      });

      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        print('Cloudinary: Image uploaded successfully');
        return {
          'success': true,
          'url': response.data['secure_url'],
          'publicId': response.data['public_id'],
        };
      } else {
        print('Cloudinary: Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = 'Dio Error: ${e.response?.statusCode} - ${e.response?.data}';
      }
      print('Cloudinary: $errorMsg');
      return {'success': false, 'error': errorMsg};
    }
  }

  // Delete resource from Cloudinary
  Future<bool> deleteResource(String publicId, String resourceType) async {
    try {
      // Generate timestamp
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create signature for authenticated request
      String stringToSign =
          'public_id=$publicId&timestamp=$timestamp${AppConstants.cloudinaryApiSecret}';
      String signature = sha1.convert(utf8.encode(stringToSign)).toString();

      FormData formData = FormData.fromMap({
        'public_id': publicId,
        'signature': signature,
        'api_key': AppConstants.cloudinaryApiKey,
        'timestamp': timestamp,
      });

      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/$resourceType/destroy',
        data: formData,
      );

      return response.statusCode == 200 && response.data['result'] == 'ok';
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  // Generate thumbnail URL from video URL
  String generateThumbnail(String videoUrl) {
    // Cloudinary transformation to get video thumbnail
    return videoUrl.replaceAll('/upload/', '/upload/c_thumb,w_400,h_300/');
  }
}
