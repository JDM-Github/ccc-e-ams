import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestHandler {
  static bool useLiveUrl = true;
  String get baseUrl {
    return RequestHandler.useLiveUrl ? 'https://ccc-e-ams.netlify.app' : 'https://dce78043--ojt-ams.netlify.live';
  }

  Future<Map<String, dynamic>> handleRequest(
    String endpoint, {
    String method = 'POST',
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/.netlify/functions/api/$endpoint');
      final defaultHeaders = {'Content-Type': 'application/json'};
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers ?? defaultHeaders);
          break;
        case 'POST':
          response = await http.post(url, headers: headers ?? defaultHeaders, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers ?? defaultHeaders, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers ?? defaultHeaders, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(
            url,
            headers: headers ?? defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return responseData;
      } else if (responseData['success'] == false) {
        return {'success': false, 'message': responseData['message'] ?? "Invalid request."};
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      return {'success': false, 'message': 'Request failed: $e'};
    }
  }
}
