import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '/api_config.dart';
import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';

class ImageUploadService {
  static final Dio _dio = Dio();

  static Future<String?> pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final token = GetIt.I<AbstractJWTTokensRepository>().getAccessToken();
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });

    final response = await _dio.post(
      '${ApiConfig.apiSiteUrl}/products/upload-image',
      data: form,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data;
    if (data is Map && data['image_url'] != null) {
      return data['image_url'] as String;
    }
    return null;
  }
}
