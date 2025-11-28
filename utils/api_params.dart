/// Common API parameter names used across different endpoints
/// This helps maintain consistency in API requests
class ApiParams {
  ApiParams._();

  // User related
  static const String id = 'id';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String fullName = 'fullName';
  static const String email = 'email';
  static const String countryCode = 'countryCode';
  static const String phone = 'phone';
  static const String phoneNumber = 'phoneNumber';
  static const String userId = 'userId';
  static const String profileImage = 'profileImage';
  static const String name = 'name';
  static const String role = 'role';

  // Authentication
  static const String otp = 'otp';
  static const String deviceId = 'deviceId';
  static const String fcmToken = 'fcmToken';

  // Pagination
  static const String page = 'page';
  static const String limit = 'limit';
  static const String search = 'search';

  // Location
  static const String lat = 'lat';
  static const String long = 'long';
  static const String addressId = 'addressId';

  // Business
  static const String businessName = 'businessName';
  static const String businessId = 'businessId';
  static const String workspaceId = 'workspaceId';
  static const String businessInfoId = 'businessInfoId';

  // Service
  static const String serviceId = 'serviceId';
  static const String isAvailable = 'isAvailable';
  static const String serviceType = 'serviceType';
  static const String categoryId = 'categoryId';
  static const String subcategoryId = 'subcategoryId';
  static const String price = 'price';
  static const String priceType = 'priceType';
  static const String duration = 'duration';
  static const String description = 'description';
  static const String termsAndCondition = 'termsAndCondition';
  static const String availableFor = 'availableFor';
  static const String validFor = 'validFor';
  static const String noOfServices = 'noOfServices';

  // Booking
  static const String date = 'date';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String startTime = 'startTime';
  static const String bookServiceId = 'bookServiceId';

  // Payment
  static const String chargeId = 'chargeId';
  static const String isFree = 'isFree';

  // Generic
  static const String status = 'status';
  static const String type = 'type';
}

