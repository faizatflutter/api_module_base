import 'package:dartz/dartz.dart';
import 'models/error_detail.dart';
import 'models/model_multipart_file.dart';

/// Abstract API Provider interface
/// Define own methods of all types of api's. Like., GET, POST..etc
abstract class ApiProvider {
  Future<Either<ErrorDetail, dynamic>?> getMethod<T>(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  });

  Future<Either<ErrorDetail, dynamic>?> postMethod<T>(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  });

  Future<Either<ErrorDetail, dynamic>?> putMethod<T>(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  });

  Future<Either<ErrorDetail, dynamic>?> updateMethod<T>(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  });

  Future<Either<ErrorDetail, dynamic>?> deleteMethod<T>(
    String url, {
    Map<String, dynamic>? query,
  });

  Future<Either<ErrorDetail, dynamic>?> postMultipartMethod<T>(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    List<ModelMultiPartFile>? files,
  });

  Future<Either<ErrorDetail, dynamic>?> updateMultipartMethod<T>(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    List<ModelMultiPartFile>? files,
  });
}

