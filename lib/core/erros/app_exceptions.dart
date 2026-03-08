/// Base class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? details;

  const AppException(this.message, {this.details});

  @override
  String toString() => message;
}

/// No internet connection
class NoInternetException extends AppException {
  const NoInternetException()
      : super(
          'No internet connection',
          details: 'Please check your network and try again.',
        );
}

/// Request timed out
class TimeoutException extends AppException {
  const TimeoutException()
      : super(
          'Request timed out',
          details: 'The server took too long to respond. Please try again.',
        );
}

/// Server returned an error (4xx / 5xx)
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({String? message, this.statusCode})
      : super(
          message ?? 'Server error',
          details: statusCode != null ? 'Status code: $statusCode' : null,
        );
}

/// Authentication / authorization error
/// ⚠️ Named AppAuthException (not AuthException) to avoid conflict with supabase_flutter
class AppAuthException extends AppException {
  const AppAuthException([String message = 'Authentication failed'])
      : super(message);
}

/// Any other unexpected error
class UnknownException extends AppException {
  const UnknownException([String message = 'An unexpected error occurred'])
      : super(message);
}