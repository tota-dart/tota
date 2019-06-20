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
  var subDir = Directory(p.join(targetUri.path, '.git'));
  if (await subDir.exists()) {
    await subDir.delete(recursive: true);
  }

  // Create config file from example.
  var file = File(p.join(targetUri.path, '.env.example'));
  if (await file.exists()) {
    await file.rename(p.join(targetUri.path, '.env'));
  }
}
