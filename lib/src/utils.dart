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
String getenv(String key, {String fallback, String prefix = 'TOTA_'}) {
  var value = dotenv.env['$prefix${key ?? fallback}'];
  if (value == null) {
    throw TotaException('configuration variable not found: `$prefix$key`');
  }
  return value;
}
