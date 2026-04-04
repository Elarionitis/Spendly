import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  final String cloudName = "dqrrzwb59";

  Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = 'unsigned_preset' // create in dashboard
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resData = await response.stream.bytesToString();
      final data = json.decode(resData);
      return data['secure_url']; // 🔥 THIS is your image URL
    } else {
      return null;
    }
  }
}