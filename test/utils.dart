import 'dart:io';

import 'package:tota/tota.dart';

/// Creates a temp directory in the system temp directory, whose name will be
/// 'tota_' with characters appended to it to make a unique name.
///
/// Returns the path of the created directory.
String _createSystemTempDir() {
  var tempDir = Directory.systemTemp.createTempSync('tota_');
  return tempDir.resolveSymbolicLinksSync();
}

/// Copies fixtures directory to [tempDir].
ProcessResult _copyFixturesToTempDir(String tempDir) {
  return Process.runSync('rsync', ['-a', 'test/fixtures/', tempDir]);
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

/// Creates a temporary directory with test fixtures and passes config to [fn].
///
/// Once the [Future] returned by [fn] completes, the temporary directory and
/// all its contents are deleted. [fn] can also return `null`, in which case
/// the temporary directory is deleted immediately afterwards.
///
/// Returns a future that completes to the value that the future returned from
/// [fn] completes to.
Future<T> withFixtures<T>(Future<T> fn(Config config)) async {
  var tempDir = _createSystemTempDir();
  var config = createTestConfig(tempDir);
  _copyFixturesToTempDir(tempDir);
  try {
    return await fn(config);
  } finally {
    await Directory(tempDir).delete(recursive: true);
  }
}

/// Creates a test config with [path] as root directory.
Config createTestConfig(String path, {String dateFormat}) {
  return createConfig(
    url: 'https://test',
    title: 'test',
    description: 'test',
    author: 'test',
    language: 'en',
    rootDir: path,
    publicDir: 'public/',
    pagesDir: 'pages/',
    postsDir: 'posts/',
    templatesDir: 'templates/',
    assetsDir: 'assets/',
    dateFormat: dateFormat ?? 'DD-MM-YYYY',
    permalink: '',
  );
}
