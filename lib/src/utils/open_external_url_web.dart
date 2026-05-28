// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  html.window.open(uri.toString(), '_blank');
  return true;
}
