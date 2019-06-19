import 'dart:io';
import 'package:path/path.dart' as p;

/// Creates a temp directory in the system temp directory, whose name will be
/// 'tota_' with characters appended to it to make a unique name.
///
/// Returns the path of the created directory.
String _createSystemTempDir() {
  var tempDir = Directory.systemTemp.createTempSync('tota_');
  return tempDir.resolveSymbolicLinksSync();
}

/// Creates a temporary directory and passes its path to [fn].
///
/// Once the [Future] returned by [fn] completes, the temporary directory and
/// all its contents are deleted. [fn] can also return `null`, in which case
/// the temporary directory is deleted immediately afterwards.
///
/// Returns a future that completes to the value that the future returned from
/// [fn] completes to.
Future<T> withTempDir<T>(Future<T> fn(String path)) async {
  var tempDir = _createSystemTempDir();
  try {
    return await fn(tempDir);
  } finally {
    await Directory(tempDir).delete(recursive: true);
  }
}

/// Creates test files in the temp directory.
///
/// Bootstraps a directory in the [tempDir] path, with test files
/// to run the test suite against.
Map<String, dynamic> createTestFiles(String tempDir, List<String> fileIds) {
  // Create source directory
  var pagesDir = Directory(p.join(tempDir, 'pages'))..createSync();
  // Generate test pages.
  var files = List<Uri>.generate(fileIds.length,
      (i) => Uri.file(p.join(pagesDir.path, 'test-${fileIds[i]}.md')));
  // Write file contents.
  files.asMap().forEach((i, uri) {
    var file = File.fromUri(uri);
    file.writeAsStringSync('---\n'
        'test: "${fileIds[i]}"\n'
        'public: true\n'
        '---\n'
        '# Hello, world!');
  });

  // Create test HTML templates.
  var templatesDir = Uri.directory(p.join(tempDir, 'templates'));
  Directory(p.join(templatesDir.path, '_partials'))
    ..createSync(recursive: true);
  File(p.join(templatesDir.path, 'base.mustache'))
    ..writeAsStringSync('{{ content }}');

  return <String, dynamic>{
    'files': files,
    'pagesDir': Uri.directory(pagesDir.path),
    'templatesDir': templatesDir,
    'publicDir': Uri.directory(p.join(tempDir, 'public'))
  };
}
