import 'dart:io';

import 'exceptions.dart';

/// URL of the source git repository.
final Uri repoUrl = Uri.https('github.com', 'tota-dart/tota-starter.git');

/// Clones the directory from GitHub to target directory.
Future<void> clone(Uri targetUri) async {
  var results = await Process.run(
      'git', ['clone', repoUrl.toString(), targetUri.toFilePath()]);
  if (results.exitCode != 0) {
    throw TotaException(results.stderr);
  }

  // Remove .git directory to enable new git project initialization.
  var gitDir = Directory.fromUri(targetUri.resolve('.git'));
  if (await gitDir.exists()) {
    await gitDir.delete(recursive: true);
  }
}
