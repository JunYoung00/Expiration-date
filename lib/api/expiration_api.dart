import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>?> fetchExpirationInfo(String name) async {
  final url = Uri.parse('http://192.168.35.33:8080/search?name=$name'); // 실기기면 IP 주소로 변경

  try {
    final response = await http.get(url);
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
