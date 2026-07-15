/// Base exception for all app exceptions
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Network connectivity errors
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Server errors (5xx)
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Validation errors (400, 422)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(super.message, {super.code, this.fieldErrors});
}

/// Unauthorized (401)
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.code});
}

/// Forbidden (403)
class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.code});
}

/// Not found (404)
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

/// Conflict (409) - e.g., duplicate phone number
class ConflictException extends AppException {
  const ConflictException(super.message, {super.code});
}

/// Cache / local storage errors
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// OTP-specific errors
class OtpException extends AppException {
  final int? remainingAttempts;
  final int? lockoutSeconds;

  const OtpException(
    super.message, {
    super.code,
    this.remainingAttempts,
    this.lockoutSeconds,
  });
}
