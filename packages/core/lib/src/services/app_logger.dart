import 'package:logger/logger.dart';

class AppLogger {
  AppLogger({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void error(Object error, [StackTrace? stackTrace]) {
    _logger.e('Unhandled application error', error: error, stackTrace: stackTrace);
  }
}
