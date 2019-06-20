import 'package:path/path.dart' as p;
import 'utils.dart';

class _Config {
  /// The current working directory.
  Uri rootDir;

  /// Allows config variables to be empty (mainly used in testing).
  bool allowEmpty = false;

  _Config(this.rootDir);

  /// Creates a URI to a directory relative to the root directory.
  Uri _createUri(String path) => Uri.directory(p.join(rootDir.path, path));

  // Gets the config variable from the environment variables.
  String _getenv(String name, {String fallback, bool allowEmpty}) =>
      getenv(name, fallback: fallback, allowEmpty: allowEmpty);

  Uri get publicDir => _createUri(_getenv('PUBLIC_DIR', fallback: 'public'));

  Uri get pagesDir => _createUri(_getenv('PAGES_DIR', fallback: 'pages'));

  Uri get postsDir => _createUri(_getenv('POSTS_DIR', fallback: 'posts'));

  Uri get templatesDir =>
      _createUri(_getenv('TEMPLATES_DIR', fallback: 'templates'));
}

final _Config config = _Config(Uri.directory(p.current));
