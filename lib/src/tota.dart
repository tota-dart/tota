library tota;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'utils.dart';
import 'pages.dart';
import 'posts.dart';

/// Runs the main build sequence for the generator.
Future<Map<String, dynamic>> build({bool deploy = false}) async {
  // Load site config file.
  var config = Config(File(p.join(p.current, 'config.yaml')));
  var result = <String, dynamic>{};

  // Build all pages.
  var pages = Pages(config);
  result['pages'] = await pages.build();

  // Build all posts.
  var posts = Posts(config);
  result['posts'] = await posts.build();

  if (deploy) {
    // TODO
    print('TODO deploy');
  }

  return result;
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
