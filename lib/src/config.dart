import 'package:path/path.dart' as p;
import 'utils.dart';

class _Config {
  /// The current working directory.
  Uri rootDir;

  /// Allows config variables to be empty (mainly used in testing).
  bool allowEmpty = false;

  _Config(this.rootDir);

  // Resolves a directory [name] relative to the [rootDir].
  // Also forces directories to have a trailing slash.
  Uri _resolveDir(String name) =>
      rootDir.resolve(name.endsWith('/') ? name : '$name/');

  Uri get publicDir => _resolveDir(getenv('PUBLIC_DIR',
      fallback: 'public', isDirectory: true, allowEmpty: allowEmpty));

  Uri get pagesDir => _resolveDir(getenv('PAGES_DIR',
      fallback: 'pages', isDirectory: true, allowEmpty: allowEmpty));

  Uri get postsDir => _resolveDir(getenv('POSTS_DIR',
      fallback: 'posts', isDirectory: true, allowEmpty: allowEmpty));

  Uri get templatesDir => _resolveDir(getenv('TEMPLATES_DIR',
      fallback: 'templates', isDirectory: true, allowEmpty: allowEmpty));

  Uri get assetsDir => _resolveDir(getenv('ASSETS_DIR',
      fallback: 'assets', isDirectory: true, allowEmpty: allowEmpty));
}

final _Config config = _Config(Uri.directory(p.current));
