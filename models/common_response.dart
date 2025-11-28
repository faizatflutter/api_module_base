import 'error_detail.dart';

/// Common response model to wrap all API responses
class CommonResponse<T> {
  int? statusCode;
  String? message;
  dynamic responseData;
  List<ErrorDetail>? errors;
  bool success = false;
  Meta? meta;

  CommonResponse({
    this.statusCode,
    this.message,
    this.responseData,
    this.errors,
    this.success = false,
    this.meta,
  });

  bool get isSuccess => success || statusCode == 200 || statusCode == 201;

  bool get isTokenExpired => statusCode == 401;

  CommonResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] ?? false;
    statusCode = _parseStatusCode(json['statusCode']);

    // Handle errors if present
    if (json.containsKey('errors') && json['errors'] != null) {
      errors = <ErrorDetail>[];
      if (json['errors'] is List) {
        json['errors'].forEach((error) {
          errors!.add(ErrorDetail.fromJson(error));
        });
      }
    } else {
      try {
        message = json['message'] ?? json['data']?['message'];
      } catch (e) {
        message = '';
      }
    }

    // Handle data if present
    if (json.containsKey('data') && json['data'] != null) {
      if ((json['data'] is Map) && (json['data'] as Map).containsKey('result') && json['data']['result'] != null) {
        responseData = getResponseData(json['data']['result']);
      } else {
        responseData = getResponseData(json['data']);
      }
      if ((json['data'] is Map) && (json['data'] as Map).containsKey('meta') && json['data']['meta'] != null) {
        meta = Meta.fromJson(json['data']['meta']);
      }
    }

    // Set appropriate message from errors if not already set
    if (message == null && errors != null && errors!.isNotEmpty) {
      message = errors!.map((error) => error.message).join(', ');
    }
  }

  int? _parseStatusCode(dynamic statusCode) {
    if (statusCode == null) return null;
    if (statusCode is int) return statusCode;
    if (statusCode is String) return int.tryParse(statusCode);
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['statusCode'] = statusCode;
    data['message'] = message;

    if (responseData != null) {
      data['data'] = responseData is List
          ? responseData.map((item) => item.toJson()).toList()
          : responseData.toJson();
    }

    if (errors != null) {
      data['errors'] = errors!.map((error) => error.toJson()).toList();
    }

    return data;
  }

  @override
  String toString() {
    return 'CommonResponse{success: $success, statusCode: $statusCode, message: $message, responseData: $responseData, errors: $errors}';
  }

  /// To get response data either in list or models
  dynamic getResponseData(dynamic json) {
    if (json is List) {
      List<T> list = [];
      for (var element in json) {
        list.add(getModelValue(element));
      }
      return list;
    } else {
      return getModelValue(json);
    }
  }

  /// To retrieve generic specific model value from json
  /// TODO: Add your specific model types here
  dynamic getModelValue(dynamic json) {
    switch (T) {
      case const (Meta):
        return Meta.fromJson(json);

      case const (Map<String, dynamic>):
        return json;

      case const (String):
        return json.toString();

      // TODO: Add your custom model types here
      // case const (YourCustomModel):
      //   return YourCustomModel.fromJson(json);

      default:
        // Return raw json if type not recognized
        return json;
    }
  }

  /// Create a CommonResponse from an error
  static CommonResponse<T> fromError<T>(dynamic error) {
    // Handle structured errors
    if (error is Map<String, dynamic>) {
      return CommonResponse<T>.fromJson(error);
    }

    // Handle simple string errors or exceptions
    return CommonResponse<T>(
      statusCode: 500,
      message: error.toString(),
      success: false,
    );
  }
}

/// Meta class for pagination information
class Meta {
  Meta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final int? total;
  final int? page;
  final int? limit;
  final int? totalPages;
  final bool? hasNextPage;
  final bool? hasPreviousPage;

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      total: json["total"],
      page: json["page"],
      limit: json["limit"],
      totalPages: json["totalPages"],
      hasNextPage: json["hasNextPage"],
      hasPreviousPage: json["hasPreviousPage"],
    );
  }

  Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": totalPages,
        "hasNextPage": hasNextPage,
        "hasPreviousPage": hasPreviousPage,
      };
}

