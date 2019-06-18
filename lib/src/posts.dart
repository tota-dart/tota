import 'package:path/path.dart' as p;
import 'pages.dart';
import 'utils.dart';

class Posts extends Pages {
  /// Gets the posts directory URI.
  @override
  Uri get sourceDir => dirs.posts;

  /// Gets the public directory URI.
  ///
  /// Adds an additional sub-directory path to the public directory,
  /// so that posts are nested inside the public directory.
  @override
  Uri get publicDir => Uri.directory(p.join(dirs.public.path, 'posts'));
}
