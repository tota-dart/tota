import 'dart:io';
import 'package:path/path.dart' as p;
import 'pages.dart';
import 'config.dart';

const _defaultDirName = 'posts';

class Posts extends Pages {
  Posts(Config config) : super(config) {
    var dirName = this.config.directory.containsKey('posts')
        ? this.config.directory['posts']
        : _defaultDirName;
    this.sourceDir = Directory(p.join(p.current, dirName));
    // The posts are nested in a sub-directory inside the public one,
    // with the same name as the source directory.
    this.publicDir = Directory(p.join(this.publicDir.path, dirName));
  }
}
