import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>?> fetchExpirationInfo(String name) async {
  final url = "https://ac2c-39-120-34-174.ngrok-free.app/search?name=$name"; // 실기기면 IP 주소로 변경

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  } catch (e) {
    print("API 요청 실패: $e");
    return null;
  }
}