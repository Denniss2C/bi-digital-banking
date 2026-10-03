import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = RequestOptions(path: '/rates');

  DioException typed(DioExceptionType type) =>
      DioException(requestOptions: options, type: type, message: 'boom');

  DioException status(int code) => DioException.badResponse(
    statusCode: code,
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: code),
  );

  group('mapDioException', () {
    test('timeouts and connection errors become NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(mapDioException(typed(type)), isA<NetworkFailure>());
      }
    });

    test('401 and 403 become AuthFailure', () {
      expect(mapDioException(status(401)), isA<AuthFailure>());
      expect(mapDioException(status(403)), isA<AuthFailure>());
    });

    test('other HTTP errors become ServerFailure with the status code', () {
      final failure = mapDioException(status(500));

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('unknown errors become ServerFailure', () {
      expect(
        mapDioException(typed(DioExceptionType.unknown)),
        isA<ServerFailure>(),
      );
    });
  });

  test('failures compare by value', () {
    expect(const NetworkFailure('x'), const NetworkFailure('x'));
    expect(
      const ServerFailure(statusCode: 500),
      isNot(const ServerFailure(statusCode: 503)),
    );
  });
}
