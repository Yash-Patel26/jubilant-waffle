import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gamer_flick/config/environment.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String get baseUrl => Environment.apiBaseUrl;
  
  // Headers with Auth Token
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Get current session token from Supabase if we are migrating
    // Or from a securely stored local token if purely using custom backend
    // For now, let's assume we might use the custom backend's token
    // But if we are integrating, we might need a way to store it.
    // Let's placeholder this:
    // final token = ...; 
    // if (token != null) headers['Authorization'] = 'Bearer $token';
    
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(url, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        url, 
        headers: _headers,
        body: body != null ? jsonEncode(body) : null
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(
        url, 
        headers: _headers,
        body: body != null ? jsonEncode(body) : null
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.delete(url, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body; // Return string if not JSON
      }
    } else {
      // Handle errors
      String message = 'Unknown error';
      try {
        final body = jsonDecode(response.body);
        message = body['detail'] ?? body['message'] ?? message;
      } catch (_) {
        message = response.body;
      }
      throw Exception('API Error ${response.statusCode}: $message');
    }
  }
}
