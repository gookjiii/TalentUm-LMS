import 'dart:io';

void main() {
  final dir = Directory('lib/src/firebase');
  for (final entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.dart') && entity.path.contains('school_repository')) {
      var content = entity.readAsStringSync();
      if (!content.contains("import 'safe_firestore.dart';")) {
        // Find the last import statement
        final importMatches = RegExp(r"import '.*';\n").allMatches(content);
        if (importMatches.isNotEmpty) {
          final lastMatch = importMatches.last;
          content = content.replaceRange(lastMatch.end, lastMatch.end, "import 'safe_firestore.dart';\n");
        } else {
          content = "import 'safe_firestore.dart';\n" + content;
        }
        entity.writeAsStringSync(content);
        print('Patched ${entity.path}');
      }
    }
  }
}
