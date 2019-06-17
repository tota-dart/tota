import 'package:path/path.dart' as p;
import 'pages.dart';
import 'utils.dart';

class Posts extends Pages {
  /// Dirname of the posts directory.
  final String _dirname = getenv('POSTS_DIR', fallback: 'posts');

  /// Gets the posts directory URI.
  @override
  Uri get sourceDir => Uri.directory(p.join(p.current, this._dirname));

  /// Gets the public directory URI.
  ///
  /// Adds an additional sub-directory path to the public directory,
  /// so that posts are nested inside the public directory.
  @override
  Uri get publicDir => Uri.directory(p.join(
      p.current, getenv('PUBLIC_DIR', fallback: 'pages'), this._dirname));
}
