import 'dart:async';
import 'dart:convert';
import 'dart:developer' as smart_logger;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'api_provider.dart';
import 'connectivity_manager.dart';
import 'models/common_response.dart';
import 'models/error_detail.dart';
import 'models/model_multipart_file.dart';

/// ApiService class implements ApiProvider interface to handle all HTTP requests
/// This service provides methods for GET, POST, PUT, PATCH, DELETE and multipart requests
/// with appropriate error handling and authentication management
class ApiService implements ApiProvider {
  /// Base URL for API - Update this with your API base URL
  static String baseUrl = 'https://api.example.com';

  /// Returns common headers for API requests, including authentication tokens
  ///
  /// @param additionalHeaders Optional headers to merge with common headers
  /// @return Map of HTTP headers with authentication tokens if available
  Map<String, String> _getCommonHeaders({Map<String, String>? additionalHeaders}) {
    // TODO: Replace with your own token management logic
    String? token = _getAuthToken();
    String? languageCode = _getLanguageCode();

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept-Language': languageCode ?? 'en',
      if (token != null && token.isNotEmpty) "Authorization": 'Bearer $token',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// TODO: Replace with your own auth token retrieval logic
  String? _getAuthToken() {
    // Example: return SharedPreferences.getString('authToken');
    return null;
  }

  /// TODO: Replace with your own language code logic
  String? _getLanguageCode() {
    // Example: return Locale.current.languageCode;
    return 'en';
  }

  /// TODO: Replace with your own loading indicator logic
  void _showLoading(bool show) {
    // Example: LoadingOverlay.show(show);
  }

  /// Return curl command for API requests
  String _generateCurlCommand({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    dynamic body,
    List<ModelMultiPartFile>? files,
  }) {
    final buffer = StringBuffer();

    buffer.write('\n');
    buffer.write('curl -X $method');

    // Add headers
    headers.forEach((key, value) {
      buffer.write(' -H "$key: $value"');
    });

    // Handle multipart form data with files
    if (files != null && files.isNotEmpty) {
      // Add form fields
      if (body != null && body is Map<String, dynamic>) {
        body.forEach((key, value) {
          if (value != null) {
            final fieldValue = value is String ? value : jsonEncode(value);
            buffer.write(' -F "$key=${fieldValue.replaceAll('"', '\\"')}"');
          }
        });
      }

      // Add files
      for (final file in files) {
        final fieldName = file.apiKey.isNotEmpty ? file.apiKey : 'file';
        final fileName = file.filePath.split('/').last;
        buffer.write(' -F "$fieldName=@${file.filePath};filename=$fileName"');
      }
    } else {
      // Handle regular JSON body
      if (body != null) {
        final bodyString = body is String ? body : jsonEncode(body);
        buffer.write(" -d '${bodyString.replaceAll("'", "\\'")}'");
      }
    }

    buffer.write(' "$uri"');
    buffer.write('\n');
    return buffer.toString();
  }

  /// Core method to send HTTP requests using the http package
  /// Handles internet connectivity check, request preparation, and response parsing
  ///
  /// @param method The HTTP method type (_ApiType enum)
  /// @param url The API endpoint URL
  /// @param query Optional query parameters
  /// @param body Optional request body
  /// @param headers Optional additional headers
  /// @param withFullResponse Whether to return full response or just response data
  /// @return Either an error wrapper or the response data/full response
  Future<Either<ErrorDetail, dynamic>?> _sendRequest<T>(
    _ApiType method,
    String url, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
    bool withFullResponse = false,
    int retryCount = 0,
    bool showLoader = false,
  }) async {
    try {
      if (showLoader) _showLoading(true);

      // Check internet connectivity before making request
      if (!await ConnectivityManager().checkInternet()) {
        return Left(ErrorDetail(statusCode: 0, message: 'No internet connection. Please check your network.'));
      }

      // Build full URL with query parameters if provided
      final Uri uri = Uri.parse(url).replace(queryParameters: query);

      // Prepare request headers
      final requestHeaders = _getCommonHeaders(additionalHeaders: headers);
      final curl = _generateCurlCommand(method: method.name.toUpperCase(), uri: uri, headers: requestHeaders, body: body);

      smart_logger.log(curl, name: "CURL-${url.split(baseUrl).last}");

      // Initialize response variable
      http.Response response;

      // Send request based on HTTP method type
      switch (method) {
        case _ApiType.get:
          response = await http.get(uri, headers: requestHeaders);
          break;
        case _ApiType.post:
          response = await http.post(uri, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
        case _ApiType.put:
          response = await http.put(uri, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
        case _ApiType.patch:
          response = await http.patch(uri, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
        case _ApiType.delete:
          response = await http.delete(uri, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
      }

      // Parse response body into JSON
      final json = jsonDecode(response.body);
      final commonResponse = CommonResponse<T>.fromJson(json);

      // Log response details for debugging
      smart_logger.log(
        '\n${commonResponse.isSuccess ? '✅Success ${response.body}' : '❌Error: ${commonResponse.message}'} \nStatusCode: ${response.statusCode}',
        name: "Response-${url.split(baseUrl).last}",
      );

      // Handle token expiration with automatic token regeneration
      if (commonResponse.isTokenExpired) {
        if (retryCount >= 3) {
          return Left(ErrorDetail(statusCode: 401));
        }

        // TODO: Add your token refresh logic here
        // await refreshAuthToken();

        // Retry the request with the new token
        return _sendRequest<T>(
          method,
          url,
          query: query,
          body: body,
          headers: headers,
          withFullResponse: withFullResponse,
          retryCount: retryCount + 1,
          showLoader: showLoader,
        );
      }

      // Return response data based on success and desired format
      return commonResponse.isSuccess
          ? withFullResponse
              ? Right(commonResponse) // Return full response object
              : Right(commonResponse.responseData) // Return just the data portion
          : Left(ErrorDetail.fromJson(json)); // Return error details
    } on http.ClientException catch (e) {
      // Handle network connectivity issues
      debugPrint('Network Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 0, message: _getNetworkErrorMessage(e.toString())));
    } on SocketException catch (e) {
      // Handle socket connection issues
      debugPrint('Socket Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 0, message: _getSocketErrorMessage(e.toString())));
    } on TimeoutException catch (e) {
      // Handle request timeout
      debugPrint('Timeout Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 408, message: 'Request timeout. Please try again.'));
    } on FormatException catch (e) {
      // Handle JSON parsing errors
      debugPrint('Format Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 500, message: 'Invalid response format from server.'));
    } catch (e, s) {
      debugPrint('Unexpected Error: ${e.toString()}');
      debugPrint('Stack Trace: ${s.toString()}');
      // Handle unexpected errors
      return Left(ErrorDetail(statusCode: 0, message: 'Something went wrong. Please try again.'));
    } finally {
      if (showLoader) _showLoading(false);
    }
  }

  /// Performs an HTTP GET request
  @override
  Future<Either<ErrorDetail, dynamic>?> getMethod<T>(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withFullResponse = false,
    bool showLoader = false,
  }) async {
    return _sendRequest<T>(_ApiType.get, url, query: query, headers: headers, withFullResponse: withFullResponse, showLoader: showLoader);
  }

  /// Performs an HTTP POST request
  @override
  Future<Either<ErrorDetail, dynamic>?> postMethod<T>(
    String url,
    dynamic body, {
    Map<String, String>? headers,
    bool withFullResponse = false,
    Map<String, dynamic>? query,
    bool showLoader = false,
  }) async {
    return _sendRequest<T>(
      _ApiType.post,
      url,
      body: body,
      headers: headers,
      withFullResponse: withFullResponse,
      query: query,
      showLoader: showLoader,
    );
  }

  /// Performs an HTTP PUT request
  @override
  Future<Either<ErrorDetail, dynamic>?> putMethod<T>(
    String url,
    dynamic body, {
    Map<String, String>? headers,
    bool withFullResponse = false,
    bool showLoader = false,
  }) async {
    return _sendRequest<T>(_ApiType.put, url, body: body, headers: headers, withFullResponse: withFullResponse, showLoader: showLoader);
  }

  /// Performs an HTTP PATCH request
  @override
  Future<Either<ErrorDetail, dynamic>?> updateMethod<T>(
    String url,
    dynamic body, {
    Map<String, String>? headers,
    bool withFullResponse = false,
    bool showLoader = false,
  }) async {
    return _sendRequest<T>(_ApiType.patch, url, body: body, headers: headers, withFullResponse: withFullResponse, showLoader: showLoader);
  }

  /// Performs an HTTP DELETE request
  @override
  Future<Either<ErrorDetail, dynamic>?> deleteMethod<T>(
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool withFullResponse = false,
    bool showLoader = false,
  }) async {
    return _sendRequest<T>(_ApiType.delete, url, body: body, query: query, withFullResponse: withFullResponse, showLoader: showLoader);
  }

  /// Performs a multipart POST request to upload files
  @override
  Future<Either<ErrorDetail, dynamic>?> postMultipartMethod<T>(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    List<ModelMultiPartFile>? files,
    bool withFullResponse = false,
    bool showLoader = false,
  }) async {
    try {
      if (showLoader) _showLoading(true);

      // Check internet connectivity
      if (!await ConnectivityManager().checkInternet()) {
        return Left(ErrorDetail(statusCode: 0, message: 'No internet connection. Please check your network.'));
      }

      // Build full URL with query parameters
      final Uri uri = Uri.parse(url).replace(queryParameters: query);

      // Create multipart request for file upload
      var request = http.MultipartRequest('POST', uri);

      // Add headers to the request
      final requestHeaders = _getCommonHeaders(additionalHeaders: headers);
      request.headers.addAll(requestHeaders);

      // Add form fields to the request (JSON-encode non-String values)
      if (body.isNotEmpty) {
        body.forEach((key, value) {
          if (value == null) return;
          if (value is String) {
            request.fields[key] = value;
          } else {
            request.fields[key] = jsonEncode(value);
          }
        });
      }

      // Add files to the request if provided (use apiKey as field name)
      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          final fieldName = file.apiKey.isNotEmpty ? file.apiKey : 'file';
          final httpFile = await http.MultipartFile.fromPath(fieldName, file.filePath, filename: file.filePath.split('/').last);
          request.files.add(httpFile);
        }
      }

      final curl = _generateCurlCommand(method: "POST", uri: uri, headers: requestHeaders, body: body, files: files);
      smart_logger.log(curl, name: "CURL-${url.split(baseUrl).last}");

      // Send the multipart request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final json = jsonDecode(response.body);
      final commonResponse = CommonResponse<T>.fromJson(json);

      smart_logger.log(
        '\n${commonResponse.isSuccess ? '✅Success ${response.body}' : '❌Error: ${commonResponse.message}'} \nStatusCode: ${response.statusCode}',
        name: "Response-${url.split(baseUrl).last}",
      );

      // Return response data based on success and desired format
      return commonResponse.isSuccess
          ? withFullResponse
              ? Right(commonResponse)
              : Right(commonResponse.responseData)
          : Left(ErrorDetail.fromJson(json));
    } catch (e, s) {
      debugPrint('Multipart Error: ${e.toString()}');
      debugPrintStack(stackTrace: s);
      return Left(ErrorDetail(statusCode: 500, message: 'Something went wrong. Please try again.'));
    } finally {
      if (showLoader) _showLoading(false);
    }
  }

  /// Performs a multipart PATCH request to update files
  @override
  Future<Either<ErrorDetail, dynamic>?> updateMultipartMethod<T>(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    List<ModelMultiPartFile>? files,
    bool withFullResponse = false,
    bool showLoader = false,
  }) async {
    try {
      if (showLoader) _showLoading(true);

      // Check internet connectivity
      if (!await ConnectivityManager().checkInternet()) {
        return Left(ErrorDetail(statusCode: 0, message: 'No internet connection. Please check your network.'));
      }

      // Build full URL with query parameters
      final Uri uri = Uri.parse(url).replace(queryParameters: query);

      // Create multipart request for file upload
      var request = http.MultipartRequest('PATCH', uri);

      // Add headers to the request
      final requestHeaders = _getCommonHeaders(additionalHeaders: headers);
      request.headers.addAll(requestHeaders);

      // Add form fields to the request (JSON-encode non-String values)
      if (body.isNotEmpty) {
        body.forEach((key, value) {
          if (value == null) return;
          if (value is String) {
            request.fields[key] = value;
          } else {
            request.fields[key] = jsonEncode(value);
          }
        });
      }

      // Add files to the request if provided (use apiKey as field name)
      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          final fieldName = file.apiKey.isNotEmpty ? file.apiKey : 'file';
          final httpFile = await http.MultipartFile.fromPath(fieldName, file.filePath, filename: file.filePath.split('/').last);
          request.files.add(httpFile);
        }
      }

      final curl = _generateCurlCommand(method: "PATCH", uri: uri, headers: requestHeaders, body: body, files: files);
      smart_logger.log(curl, name: "CURL-${url.split(baseUrl).last}");

      // Send the multipart request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final json = jsonDecode(response.body);
      final commonResponse = CommonResponse<T>.fromJson(json);

      smart_logger.log(
        '\n${commonResponse.isSuccess ? '✅Success ${response.body}' : '❌Error: ${commonResponse.message}'} \nStatusCode: ${response.statusCode}',
        name: "Response-${url.split(baseUrl).last}",
      );

      // Return response data based on success and desired format
      return commonResponse.isSuccess
          ? withFullResponse
              ? Right(commonResponse)
              : Right(commonResponse.responseData)
          : Left(ErrorDetail.fromJson(json));
    } on http.ClientException catch (e) {
      debugPrint('Network Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 0, message: _getNetworkErrorMessage(e.toString())));
    } on SocketException catch (e) {
      debugPrint('Socket Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 0, message: _getSocketErrorMessage(e.toString())));
    } on TimeoutException catch (e) {
      debugPrint('Timeout Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 408, message: 'Request timeout. Please try again.'));
    } on FormatException catch (e) {
      debugPrint('Format Error: ${e.toString()}');
      return Left(ErrorDetail(statusCode: 500, message: 'Invalid response format from server.'));
    } catch (e, s) {
      debugPrint('Unexpected Error: ${e.toString()}');
      debugPrint('Stack Trace: ${s.toString()}');
      return Left(ErrorDetail(statusCode: 500, message: 'Something went wrong. Please try again.'));
    } finally {
      if (showLoader) _showLoading(false);
    }
  }

  /// Generate user-friendly network error messages
  String _getNetworkErrorMessage(String error) {
    if (error.contains('Connection reset by peer')) {
      return 'Connection lost. Please check your internet connection and try again.';
    } else if (error.contains('Connection refused')) {
      return 'Unable to connect to server. Please try again later.';
    } else if (error.contains('Network is unreachable')) {
      return 'Network unreachable. Please check your internet connection.';
    } else if (error.contains('Connection timed out')) {
      return 'Connection timed out. Please try again.';
    } else if (error.contains('HandshakeException')) {
      return 'Secure connection failed. Please check your network settings.';
    } else {
      return 'Network error occurred. Please check your connection and try again.';
    }
  }

  /// Generate user-friendly socket error messages
  String _getSocketErrorMessage(String error) {
    if (error.contains('No route to host')) {
      return 'No route to host. Please check your internet connection.';
    } else if (error.contains('Address already in use')) {
      return 'Connection conflict. Please try again in a moment.';
    } else if (error.contains('Connection refused')) {
      return 'Connection refused by server. Please try again later.';
    } else {
      return 'Connection error. Please check your internet connection.';
    }
  }
}

/// Enum representing the different HTTP request methods
/// Used internally by the _sendRequest method
enum _ApiType { get, post, put, patch, delete }

