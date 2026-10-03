import 'package:core/src/errors/failure.dart';
import 'package:dio/dio.dart';

/// Maps a [DioException] (after retries) to a typed [Failure].
Failure mapDioException(DioException exception) {
  final details = exception.message ?? exception.type.name;
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkFailure(details);
    case DioExceptionType.badResponse:
      final statusCode = exception.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return AuthFailure(details);
      }
      return ServerFailure(statusCode: statusCode, message: details);
    // transformTimeout: the response arrived but decoding it took too long.
    case DioExceptionType.transformTimeout:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return ServerFailure(message: details);
  }
}
