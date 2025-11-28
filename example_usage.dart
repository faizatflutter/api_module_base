import 'package:dartz/dartz.dart';
import 'api_provider.dart';
import 'api_service.dart';
import 'models/error_detail.dart';
import 'models/model_multipart_file.dart';

/// Example usage of the Reusable API Module

void main() async {
  // Initialize the API service
  final ApiProvider apiService = ApiService();

  // Example 1: Simple GET request
  await exampleGetRequest(apiService);

  // Example 2: POST request with body
  await examplePostRequest(apiService);

  // Example 3: File upload with multipart
  await exampleFileUpload(apiService);

  // Example 4: PUT/UPDATE request
  await exampleUpdateRequest(apiService);

  // Example 5: DELETE request
  await exampleDeleteRequest(apiService);
}

/// Example 1: GET Request
Future<void> exampleGetRequest(ApiProvider apiService) async {
  print('\n=== Example 1: GET Request ===');

  final result = await apiService.getMethod<Map<String, dynamic>>(
    'https://api.example.com/users',
    query: {
      'page': '1',
      'limit': '10',
    },
  );

  result?.fold(
    (error) {
      print('❌ Error: ${error.message}');
      print('Status Code: ${error.statusCode}');
    },
    (data) {
      print('✅ Success: $data');
    },
  );
}

/// Example 2: POST Request
Future<void> examplePostRequest(ApiProvider apiService) async {
  print('\n=== Example 2: POST Request ===');

  final requestBody = {
    'firstName': 'John',
    'lastName': 'Doe',
    'email': 'john.doe@example.com',
    'phone': '+1234567890',
  };

  final result = await apiService.postMethod<Map<String, dynamic>>(
    'https://api.example.com/users',
    requestBody,
  );

  result?.fold(
    (error) => print('❌ Error: ${error.message}'),
    (data) => print('✅ User created: $data'),
  );
}

/// Example 3: File Upload with Multipart
Future<void> exampleFileUpload(ApiProvider apiService) async {
  print('\n=== Example 3: File Upload ===');

  final files = [
    ModelMultiPartFile(
      filePath: '/path/to/profile.jpg',
      apiKey: 'profileImage',
    ),
    ModelMultiPartFile(
      filePath: '/path/to/document.pdf',
      apiKey: 'document',
    ),
  ];

  final formData = {
    'userId': '12345',
    'description': 'Profile photo and document',
  };

  final result = await apiService.postMultipartMethod<Map<String, dynamic>>(
    'https://api.example.com/upload',
    formData,
    files: files,
  );

  result?.fold(
    (error) => print('❌ Upload failed: ${error.message}'),
    (data) => print('✅ Files uploaded: $data'),
  );
}

/// Example 4: PUT/UPDATE Request
Future<void> exampleUpdateRequest(ApiProvider apiService) async {
  print('\n=== Example 4: UPDATE Request ===');

  final updateData = {
    'firstName': 'Jane',
    'lastName': 'Smith',
    'phone': '+9876543210',
  };

  final result = await apiService.updateMethod<Map<String, dynamic>>(
    'https://api.example.com/users/12345',
    updateData,
  );

  result?.fold(
    (error) => print('❌ Update failed: ${error.message}'),
    (data) => print('✅ User updated: $data'),
  );
}

/// Example 5: DELETE Request
Future<void> exampleDeleteRequest(ApiProvider apiService) async {
  print('\n=== Example 5: DELETE Request ===');

  final result = await apiService.deleteMethod<Map<String, dynamic>>(
    'https://api.example.com/users/12345',
    query: {'force': 'true'},
  );

  result?.fold(
    (error) => print('❌ Delete failed: ${error.message}'),
    (data) => print('✅ User deleted: $data'),
  );
}

/// Example 6: Handling errors properly
Future<void> exampleErrorHandling(ApiProvider apiService) async {
  print('\n=== Example 6: Error Handling ===');

  final result = await apiService.getMethod<Map<String, dynamic>>(
    'https://api.example.com/protected-route',
  );

  if (result == null) {
    print('⚠️ No response received');
    return;
  }

  result.fold(
    (ErrorDetail error) {
      // Handle different error types
      switch (error.statusCode) {
        case 0:
          print('❌ Network error: ${error.message}');
          break;
        case 401:
          print('❌ Unauthorized - Token expired');
          // Navigate to login screen
          break;
        case 403:
          print('❌ Forbidden - No permission');
          break;
        case 404:
          print('❌ Not found');
          break;
        case 500:
          print('❌ Server error: ${error.message}');
          break;
        default:
          print('❌ Error ${error.statusCode}: ${error.message}');
      }
    },
    (data) {
      print('✅ Data received: $data');
    },
  );
}

/// Example 7: Using with custom models
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };
}

Future<void> exampleWithCustomModel(ApiProvider apiService) async {
  print('\n=== Example 7: Custom Model ===');

  // Note: You need to add UserModel to the getModelValue() method in common_response.dart
  final result = await apiService.getMethod<UserModel>(
    'https://api.example.com/users/12345',
  );

  result?.fold(
    (error) => print('❌ Error: ${error.message}'),
    (user) {
      if (user is UserModel) {
        print('✅ User: ${user.name} (${user.email})');
      }
    },
  );
}

/// Example 8: Pagination handling
Future<void> examplePagination(ApiProvider apiService) async {
  print('\n=== Example 8: Pagination ===');

  int currentPage = 1;
  bool hasMore = true;

  while (hasMore) {
    final result = await apiService.getMethod<List<Map<String, dynamic>>>(
      'https://api.example.com/users',
      query: {
        'page': currentPage.toString(),
        'limit': '20',
      },
      withFullResponse: true, // Get full response including meta
    );

    result?.fold(
      (error) {
        print('❌ Error: ${error.message}');
        hasMore = false;
      },
      (response) {
        // Access meta information
        if (response.meta != null) {
          print('Page ${response.meta!.page} of ${response.meta!.totalPages}');
          print('Total items: ${response.meta!.total}');

          hasMore = response.meta!.hasNextPage ?? false;
          currentPage++;
        }

        // Access data
        print('✅ Loaded ${response.responseData?.length ?? 0} items');
      },
    );

    if (!hasMore) {
      print('All pages loaded!');
    }
  }
}

