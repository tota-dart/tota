import 'dart:io';

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
