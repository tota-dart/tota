import 'dart:io';
import 'package:path/path.dart' as p;
import 'tota_exception.dart';

/// Bootstraps a new Tota project from scratch.
class Starter {
  /// URL of the source git repository.
  final Uri repoUrl = Uri.https('github.com', 'tota-dart/tota-starter.git');

  /// The destination clone target.
  final Uri targetUri;

  Starter(this.targetUri);

  // Removes a directory inside the target directory.
  Future<void> _removeDir(String name) async {
    var subDir = Directory(p.join(targetUri.path, name));
    if (await subDir.exists()) {
      subDir.delete(recursive: true);
    }
  }

  // Renames a file inside the target directory.
  Future<void> _renameFile(String from, to) async {
    var file = File(p.join(targetUri.path, from));
    if (await file.exists()) {
      await file.rename(p.join(targetUri.path, to));
    }
  }

  /// Clones the directory from GitHub.
  Future<void> clone() async {
    var results = await Process.run('git',
        ['clone', '--recursive', repoUrl.toString(), targetUri.toFilePath()]);
    if (results.exitCode != 0) {
      throw TotaException(results.stderr);
    }

    // Remove .git directory to enable new git project initialization.
    await _removeDir('.git');
    // Create config file.
    await _renameFile('.env.example', '.env');
  }
}
