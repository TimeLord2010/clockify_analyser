import 'package:dio/dio.dart';

final httpClient = Dio();

class ClockifyHttpClient {
  static set apiKey(String? value) {
    value ??= '';
    if (value.isEmpty) {
      httpClient.options.headers.remove('x-api-key');
    } else {
      httpClient.options.headers['x-api-key'] = value;
    }
  }

  static String? get apiKey {
    return httpClient.options.headers['x-api-key'];
  }
}
