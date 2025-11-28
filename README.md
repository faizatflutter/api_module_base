# Reusable API Module

A portable, generic API client module for Flutter applications that can be easily integrated into any project.

## Features

- **Type-safe API calls** with Either pattern for error handling
- **Multiple HTTP methods** support (GET, POST, PUT, PATCH, DELETE)
- **Multipart file upload** support
- **Automatic error handling** with detailed error models
- **Network connectivity checks** before API calls
- **CURL command generation** for debugging
- **Generic response parsing** with CommonResponse model
- **Authentication token management** with auto-retry on token expiration
- **Comprehensive logging** for requests and responses

## Structure

```
reusable_api_module/
├── README.md (this file)
├── api_provider.dart (Abstract interface)
├── api_service.dart (Implementation)
├── connectivity_manager.dart (Network checks)
├── models/
│   ├── error_detail.dart (Error model)
│   ├── common_response.dart (Generic response wrapper)
│   └── model_multipart_file.dart (File upload model)
└── utils/
    └── api_params.dart (Common API parameter names)
```

## Installation

### 1. Copy the module folder to your project
Copy the entire `reusable_api_module` folder to your project's `lib` directory.

### 2. Add required dependencies to `pubspec.yaml`

```yaml
dependencies:
  http: ^1.1.0
  dartz: ^0.10.1
  connectivity_plus: ^5.0.0
```

### 3. Update imports in your project
Replace the generic model retrieval in `common_response.dart` with your specific models.

## Usage

### Basic Setup

```dart
import 'package:your_app/reusable_api_module/api_service.dart';
import 'package:your_app/reusable_api_module/api_provider.dart';

// Create an instance of the API service
final ApiProvider apiService = ApiService();
```

### GET Request

```dart
final result = await apiService.getMethod<YourModel>(
  'https://api.example.com/users',
  query: {'page': '1', 'limit': '10'},
  headers: {'Custom-Header': 'value'},
);

result?.fold(
  (error) => print('Error: ${error.message}'),
  (data) => print('Success: $data'),
);
```

### POST Request

```dart
final result = await apiService.postMethod<YourModel>(
  'https://api.example.com/users',
  {'name': 'John', 'email': 'john@example.com'},
  headers: {'Content-Type': 'application/json'},
);

result?.fold(
  (error) => print('Error: ${error.message}'),
  (data) => print('Success: $data'),
);
```

### Multipart File Upload

```dart
final files = [
  ModelMultiPartFile(
    filePath: '/path/to/image.jpg',
    apiKey: 'profileImage',
  ),
];

final result = await apiService.postMultipartMethod<YourModel>(
  'https://api.example.com/upload',
  {'description': 'Profile photo'},
  files: files,
);

result?.fold(
  (error) => print('Error: ${error.message}'),
  (data) => print('Success: $data'),
);
```

### DELETE Request

```dart
final result = await apiService.deleteMethod<YourModel>(
  'https://api.example.com/users/123',
  query: {'force': 'true'},
);

result?.fold(
  (error) => print('Error: ${error.message}'),
  (data) => print('Success: $data'),
);
```

## Customization

### 1. Authentication Headers
Update the `_getCommonHeaders()` method in `api_service.dart` to customize authentication:

```dart
Map<String, String> _getCommonHeaders({Map<String, String>? additionalHeaders}) {
  String? token = YourAuthManager.getToken(); // Replace with your auth logic
  
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    if (token != null) "Authorization": 'Bearer $token',
  };
  
  if (additionalHeaders != null) {
    headers.addAll(additionalHeaders);
  }
  
  return headers;
}
```

### 2. Error Messages
Update error handling in `_sendRequest()` method to use your localization system or custom error messages.

### 3. Response Model Parsing
Update the `getModelValue()` method in `common_response.dart` to include your specific model types:

```dart
dynamic getModelValue(dynamic json) {
  switch (T) {
    case const (YourCustomModel):
      return YourCustomModel.fromJson(json);
    
    case const (Map<String, dynamic>):
      return json;
    
    default:
      throw Exception('Model type $T not supported');
  }
}
```

### 4. Loading States
Replace `AppController.instance.showLoading()` calls with your own loading indicator logic.

## Error Handling

The module uses the `Either` type from `dartz` package for functional error handling:

```dart
final result = await apiService.getMethod<YourModel>(url);

result?.fold(
  (error) {
    // Left side - Error occurred
    print('Status Code: ${error.statusCode}');
    print('Message: ${error.message}');
  },
  (data) {
    // Right side - Success
    print('Data: $data');
  },
);
```

## Response Structure

The `CommonResponse` model wraps all API responses:

```dart
class CommonResponse<T> {
  int? statusCode;
  String? message;
  dynamic responseData;
  List<ErrorDetail>? errors;
  bool success;
  Meta? meta; // For paginated responses
}
```

## Error Detail Structure

```dart
class ErrorDetail {
  final int? statusCode;
  final String? message;
  final String? error;
  final dynamic data;
}
```

## Network Connectivity

The module automatically checks for internet connectivity before making requests:

```dart
if (!await ConnectivityManager().checkInternet()) {
  return Left(ErrorDetail(
    statusCode: 0, 
    message: 'No internet connection'
  ));
}
```

## Debugging

The module generates CURL commands for each request, which are logged for debugging:

```dart
curl -X POST -H "Authorization: Bearer token" -d '{"key":"value"}' "https://api.example.com/endpoint"
```

## Token Expiration Handling

The module automatically handles token expiration (401 status) with retry logic:

```dart
if (commonResponse.isTokenExpired) {
  // Retry the request up to 3 times
  if (retryCount >= 3) {
    return Left(ErrorDetail(statusCode: 401));
  }
  
  return _sendRequest<T>(..., retryCount: retryCount + 1);
}
```

## Pagination Support

The `Meta` model provides pagination information:

```dart
class Meta {
  final int? total;
  final int? page;
  final int? limit;
  final int? totalPages;
  final bool? hasNextPage;
  final bool? hasPreviousPage;
}
```

## License

This module is part of the Owdan project and can be reused in other projects with proper attribution.

## Notes

- Replace all project-specific dependencies (like `LocaleKeys`, `StorageManager`, `AppController`) with your own implementations
- Update the `CommonResponse.getModelValue()` method to include your specific model types
- The module is designed to be framework-agnostic for the core HTTP logic
- CURL logging can be disabled by removing the log statements in the methods

## Support

For issues or questions, please refer to the main project documentation.

