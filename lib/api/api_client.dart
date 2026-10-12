import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Error returned by the VUE & OR API (`{status: "Error", message}`) or a
/// network failure.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin JSON client for the REST API shared by the website and this app.
/// Sends `Authorization: Bearer <token>` when signed in.
class ApiClient {
  final http.Client _http;
  final String baseUrl;
  String? token;

  ApiClient({http.Client? client, String? baseUrl})
    : _http = client ?? http.Client(),
      baseUrl = baseUrl ?? AppConfig.apiUrl;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, [Object? body]) => _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(String method, String path, {Map<String, String>? query, Object? body}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await _http.send(request).timeout(const Duration(seconds: 25));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('The server took too long to answer. Please try again.');
    } on SocketException {
      throw ApiException("Couldn't reach VUE & OR. Check your internet connection.");
    } on http.ClientException {
      throw ApiException("Couldn't reach VUE & OR. Check your internet connection.");
    }

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } on FormatException {
        // Non-JSON body (e.g. a proxy error page); handled below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ApiException(
      (data['message'] as String?) ?? 'Something went wrong (${response.statusCode}).',
      response.statusCode,
    );
  }
}
