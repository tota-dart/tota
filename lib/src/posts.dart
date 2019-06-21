import 'package:path/path.dart' as p;
import 'pages.dart';
import 'config.dart';
import 'utils.dart';

class Posts extends Pages {
  /// The URI for the posts directory.
  @override
  Uri sourceDir = config.postsDir;

  /// The URI for the public directory.
  ///
  /// Adds an additional sub-directory path to the public directory,
  /// so that posts are nested inside the public directory.
  @override
  Uri get publicDir => config.publicDir.resolve(_dirname);

  get _dirname {
    var name = getenv('POSTS_DIR', fallback: 'posts/');
    return name.endsWith('/') ? name : '$name/';
  }
}
