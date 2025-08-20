import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ServerOcrService {
  static const String baseHost = "http://192.168.2.27:8000";

  /// Map docType to API endpoint
  static String _endpointForDoc(String docType) {
    switch (docType) {
      case "Birth Certificate":
        return "$baseHost/birth-certificate";
      case "Residence Certificate":
        return "$baseHost/residence-certificate";
      default:
        throw Exception("No server endpoint defined for $docType");
    }
  }

  /// Upload image and get extracted data
  static Future<Map<String, dynamic>> extractFromServer(File file, String docType) async {
    final uri = Uri.parse(_endpointForDoc(docType));

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', file.path)); // 👈 field is "image"

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } else {
      throw Exception("Server OCR failed: ${response.statusCode}");
    }
  }
}
