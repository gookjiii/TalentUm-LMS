import 'splash_loader_stub.dart'
    if (dart.library.html) 'splash_loader_web.dart';

/// Dismisses the native HTML loading splash screen.
void hideSplash() {
  hideSplashImpl();
}
