import 'package:path/path.dart' as p;
import 'utils.dart';

class _Config {
  /// The current working directory.
  Uri rootDir;

  /// Allows config variables to be empty (mainly used in testing).
  bool allowEmpty = false;

  _Config(this.rootDir);

  // Gets the config variable from the environment variables.
  String _getenv(String name, {String fallback, bool allowEmpty}) =>
      getenv(name, fallback: fallback, allowEmpty: allowEmpty);

  // Resolves a directory [name] relative to the [rootDir].
  // Also forces directories to have a trailing slash.
  Uri _resolveDir(String name) =>
      rootDir.resolve(name.endsWith('/') ? name : '$name/');

  Uri get publicDir => _resolveDir(_getenv('PUBLIC_DIR', fallback: 'public/'));

  Uri get pagesDir => _resolveDir(_getenv('PAGES_DIR', fallback: 'pages/'));

  Uri get postsDir => _resolveDir(_getenv('POSTS_DIR', fallback: 'posts/'));

  Uri get templatesDir =>
      _resolveDir(_getenv('TEMPLATES_DIR', fallback: 'templates/'));
}

final _Config config = _Config(Uri.directory(p.current));
