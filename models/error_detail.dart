/// Class to handle detailed error information
class ErrorDetail {
  ErrorDetail({
    required this.statusCode,
    this.message,
    this.error,
    this.data,
  });

  final int? statusCode;
  final String? message;
  final String? error;
  final dynamic data;

  factory ErrorDetail.fromJson(Map<String, dynamic> json) {
    // Handle message potentially being a list of strings
    String? parsedMessage;
    if (json["message"] is List) {
      parsedMessage = (json["message"] as List).join(", ");
    } else {
      parsedMessage = json["message"];
    }
    return ErrorDetail(
      statusCode: json["statusCode"],
      message: parsedMessage,
      error: json["error"],
      data: json["data"],
    );
  }

  Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "error": error,
        "data": data,
      };

  @override
  String toString() {
    return "$statusCode, $message, $error, $data, ";
  }
}

