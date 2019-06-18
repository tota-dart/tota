import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart' show DateFormat;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:slugify/slugify.dart';
import 'tota_exception.dart';

/// Deletes all files in a [directory] that match a file [extension] (optional).
Future<void> emptyDirectory(Directory directory, {String extension}) async {
  await for (var file in directory.list()) {
    if ((extension?.isEmpty ?? true) || p.extension(file.path) == extension) {
      await file.delete();
    }
  }
}

/// Converts a [date] to ISO-8601 format (YYYY-MM-DD).
String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Slugifies a [text] string.
String slugify(String text) => Slugify(text);

/// Converts a [Map] to a front matter string.
///
/// Naive implementation of a YAML dump (unsupported method in `yaml` package).
String createFrontMatter(Map<String, dynamic> data) {
  if (data.isEmpty) {
    return '';
  }
  var fm = data.entries.map((entry) => '${entry.key}: ${entry.value}');
  return "---\n${fm.join('\n')}\n---";
}

/// Gets environment variable with [prefix].
String getenv(String key,
    {String fallback, String prefix = 'TOTA_', bool allowEmpty: false}) {
  var value = dotenv.env[key] ?? fallback;
  if (value == null && !allowEmpty) {
    throw TotaException('config not set: `$prefix$key`');
  }
  return value;
}

/// Has getters for notable directories relative to a common root.
class _Directories {
  /// Root directory for directories.
  String root = p.current;

  /// Toggles exceptions off (used in tests).
  bool allowEmpty = false;

  /// Resets to default options.
  void reset() {
    root = p.current;
    allowEmpty = false;
  }

  /// Returns a directory URI relative to root.
  Uri _getUri(String env, {String fallback}) => Uri.directory(
      p.join(root, getenv(env, fallback: fallback, allowEmpty: allowEmpty)));

  Uri get public => _getUri('PUBLIC_DIR', fallback: 'public');

  Uri get pages => _getUri('PAGES_DIR', fallback: 'pages');

  Uri get posts => _getUri('POSTS_DIR', fallback: 'posts');

  Uri get templates => _getUri('TEMPLATES_DIR', fallback: 'templates');
}

/// Helper that returns URIs for notable directories.
var dirs = _Directories();
