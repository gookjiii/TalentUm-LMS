import 'dart:js_interop';

@JS('_hideFlutterLoading')
external void _hideFlutterLoading();

void hideSplashImpl() {
  try {
    _hideFlutterLoading();
  } catch (_) {
    // Ignore if not present
  }
}
