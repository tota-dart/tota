import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'utils.dart';

/// Represents the site configuration settings.
class SiteConfig {
  SiteConfig({
    @required this.url,
    @required this.title,
    @required this.description,
    @required this.author,
    @required this.language,
  });

  final String url, title, description, author, language;

  Map<String, dynamic> toJson() {
    return <String, String>{
      'url': url,
      'title': title,
      'description': description,
      'author': author,
      'language': language
    };
  }
}

/// Represents the directory configuration settings.
class DirectoryConfig {
  DirectoryConfig({
    @required this.public,
    @required this.pages,
    @required this.posts,
    @required this.templates,
    @required this.assets,
  });

  final String public, pages, posts, templates, assets;

  Map<String, dynamic> toJson() {
    return <String, String>{
      'public': public,
      'pages': pages,
      'posts': posts,
      'templates': templates,
      'assets': assets
    };
  }
}

/// Combines all config sections into one entity.
class Config {
  SiteConfig site;
  DirectoryConfig dir;
  Config(this.site, this.dir);
}

/// Creates a new config instance from environment variable settings.
///
/// This method is pretty gnarly, but the config is consolidated here
/// instead of having the codebase littered with `getenv()` calls.
/// This made it easier to inject config as a dependency and create unit tests.
Config createConfig({bool allowEmpty = false}) {
  var siteConfig = SiteConfig(
    url: getenv('URL', allowEmpty: allowEmpty),
    title: getenv('TITLE', allowEmpty: allowEmpty),
    description: getenv('DESCRIPTION', allowEmpty: allowEmpty),
    author: getenv('AUTHOR', allowEmpty: allowEmpty),
    language: getenv('LANGUAGE', fallback: 'en', allowEmpty: allowEmpty),
  );

  var dirConfig = DirectoryConfig(
    public: getenv('PUBLIC_DIR',
        fallback: 'public', allowEmpty: allowEmpty, isDirectory: true),
    pages: getenv('PAGES_DIR',
        fallback: 'pages', allowEmpty: allowEmpty, isDirectory: true),
    posts: getenv('POSTS_DIR',
        fallback: 'posts', allowEmpty: allowEmpty, isDirectory: true),
    templates: getenv('TEMPLATES_DIR',
        fallback: 'templates', allowEmpty: allowEmpty, isDirectory: true),
    assets: getenv('ASSETS_DIR',
        fallback: 'assets', allowEmpty: allowEmpty, isDirectory: true),
  );

  return Config(siteConfig, dirConfig);
}
