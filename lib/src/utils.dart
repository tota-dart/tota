import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:markdown/markdown.dart';

import 'tota_exception.dart';

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
    {String fallback,
    String prefix = 'TOTA_',
    bool allowEmpty = false,
    bool isDirectory = false}) {
  var value = dotenv.env['$prefix$key'] ?? fallback;
  if (value == null && !allowEmpty) {
    throw TotaException('config not set: `$prefix$key`');
  }
  // Add a trailing slash to directories.
  if (isDirectory && !value.endsWith('/')) {
    value += '/';
  }
  return value;
}

/// Converts Markdown [text] to HTML.
String convertMarkdownToHtml(String text) =>
    markdownToHtml(text, inlineSyntaxes: [
      InlineHtmlSyntax(),
    ], blockSyntaxes: [
      HeaderWithIdSyntax(),
      TableSyntax(),
    ]);
