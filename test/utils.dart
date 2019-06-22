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
Map<String, dynamic> createTestFiles(String tempDirPath, List<String> fileIds) {
  Uri tempDir = Uri.directory(tempDirPath);

  // Create pages source directory.
  Uri pagesDir = tempDir.resolve('pages/');
  Directory.fromUri(pagesDir).createSync();

  // Generate test pages.
  var files = List<Uri>.generate(
      fileIds.length, (i) => pagesDir.resolve('test-${fileIds[i]}.md'));
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
  var templatesDir = tempDir.resolve('templates/');
  Directory.fromUri(templatesDir.resolve('_partials/'))
      .createSync(recursive: true);
  File.fromUri(templatesDir.resolve('base.mustache'))
      .writeAsStringSync('{{ content }}');

  // Create asset directory and asset file.
  var assetsDir = tempDir.resolve('assets/');
  Directory.fromUri(assetsDir).createSync();
  File.fromUri(assetsDir.resolve('index.js'))
      .writeAsStringSync('console.log("foo")');

  return <String, dynamic>{
    'files': files,
    'pagesDir': pagesDir,
    'templatesDir': templatesDir,
    'assetsDir': assetsDir,
    'publicDir': tempDir.resolve('public/')
  };
}
