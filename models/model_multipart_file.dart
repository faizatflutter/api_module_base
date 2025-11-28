/// Model class for representing a file to be uploaded in multipart requests
/// Contains the file path and the API key to be used as the field name
class ModelMultiPartFile {
  /// The path to the file on the device
  String filePath;

  /// The API key/field name to be used for this file in the request
  String apiKey;

  /// Constructor for ModelMultiPartFile
  ModelMultiPartFile({required this.filePath, required this.apiKey});
}

