library tota;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'src/config.dart';
import 'src/utils.dart';
import 'src/pages.dart';
import 'src/posts.dart';

export 'src/config.dart';
export 'src/exceptions.dart' show TotaException;

/// Runs the main build sequence for the generator.
Future<void> build() async {
  // Load site config file.
  var config = Config(File(p.join(p.current, 'config.yaml')));

  // Build all pages.
  var pages = Pages(config);
  var pagesBuilt = await pages.build();

  // Build all posts.
  var posts = Posts(config);
  var postsBuilt = await posts.build();

  print('Success.');
  print('Pages created: ${pagesBuilt.length}');
  print('Posts created: ${postsBuilt.length}');
}

Future<File> create(String title, {String type}) async {
  // Load site config file.
  var config = Config(File(p.join(p.current, 'config.yaml')));

  Pages pages = Pages(config);
  if (type == 'posts') {
    pages = Posts(config);
  }

  return pages.create(title);
}
