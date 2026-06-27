import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class GoogleDriveHelper {
  /// Extracts the direct download URL from a Google Drive file link
  static Future<Map<String, String>> getDirectDownloadLink(
    String fileId,
  ) async {
    final baseUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

    try {
      final dio = Dio(
        BaseOptions(
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      final response = await dio.get(baseUrl);
      final cookies = response.headers['set-cookie'] ?? [];

      if (response.statusCode == 302 || response.statusCode == 303) {
        final location = response.headers.value('location');
        if (location != null) {
          final nextUrl = location.startsWith('http')
              ? location
              : 'https://drive.google.com$location';

          final cookieStr = cookies.map((c) => c.split(';')[0]).join('; ');
          final warningResponse = await dio.get(
            nextUrl,
            options: Options(headers: {'Cookie': cookieStr}),
          );

          final newCookies = warningResponse.headers['set-cookie'] ?? [];
          final allCookies = [...cookies, ...newCookies];
          final finalCookieStr = allCookies
              .map((c) => c.split(';')[0])
              .join('; ');

          if (warningResponse.statusCode == 200 &&
              warningResponse.data.toString().contains('confirm=')) {
            final body = warningResponse.data.toString();
            final confirmRegex = RegExp(r'confirm=([a-zA-Z0-9_-]+)');
            final match = confirmRegex.firstMatch(body);
            if (match != null) {
              return {
                'url': '$baseUrl&confirm=${match.group(1)}',
                'cookie': finalCookieStr,
              };
            }
          }
        }
      }
      return {
        'url': baseUrl,
        'cookie': cookies.map((c) => c.split(';')[0]).join('; '),
      };
    } catch (e) {
      debugPrint('Error getting Google Drive direct link: $e');
    }

    return {'url': baseUrl, 'cookie': ''};
  }
}
