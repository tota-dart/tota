import 'dart:io';
import 'package:path/path.dart' as p;
import 'tota_exception.dart';

/// URL of the source git repository.
final Uri repoUrl = Uri.https('github.com', 'tota-dart/tota-starter.git');

/// Clones the directory from GitHub to target directory.
Future<void> clone(Uri targetUri) async {
  var results = await Process.run('git',
      ['clone', '--recursive', repoUrl.toString(), targetUri.toFilePath()]);
  if (results.exitCode != 0) {
    throw TotaException(results.stderr);
  }

  // Remove .git directory to enable new git project initialization.
  var gitDir = Directory.fromUri(targetUri.resolve('.git'));
  if (await gitDir.exists()) {
    await gitDir.delete(recursive: true);
  }

  // Create config file from example.
  var file = File.fromUri(targetUri.resolve('.env.example'));
  if (await file.exists()) {
    await file.rename(targetUri.resolve('.env').toFilePath());
  }
}
