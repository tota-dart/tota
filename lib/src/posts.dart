import 'package:path/path.dart' as p;
import 'pages.dart';
import 'utils.dart';

class Posts extends Pages {
  /// The URI for the posts directory.
  @override
  Uri sourceDir = dirs.posts;

  /// The URI for the public directory.
  ///
  /// Adds an additional sub-directory path to the public directory,
  /// so that posts are nested inside the public directory.
  @override
  Uri publicDir = Uri.directory(p.join(dirs.public.path, 'posts'));
}
