import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class RoboflowService {
  static const String _apiKey = "YOUR_ROBOFLOW_API_KEY";
  static const String _modelEndpoint = "YOUR_MODEL_ENDPOINT";

  Future<List<dynamic>> detectDisease(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
        "https://detect.roboflow.com/$_modelEndpoint?api_key=$_apiKey");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: base64Image,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['predictions'] ?? [];
    } else {
      throw Exception("Roboflow API error: ${response.statusCode}");
    }
  }
}
