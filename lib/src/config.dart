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

  Map<String, String> toJson() {
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

  Map<String, String> toJson() {
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
Config createConfig() {
  var siteConfig = SiteConfig(
    url: getenv('URL'),
    title: getenv('TITLE'),
    description: getenv('DESCRIPTION'),
    author: getenv('AUTHOR'),
    language: getenv('LANGUAGE', fallback: 'en'),
  );

  var dirConfig = DirectoryConfig(
    public: getenv('PUBLIC_DIR', fallback: 'public', isDirectory: true),
    pages: getenv('PAGES_DIR', fallback: 'pages', isDirectory: true),
    posts: getenv('POSTS_DIR', fallback: 'posts', isDirectory: true),
    templates:
        getenv('TEMPLATES_DIR', fallback: 'templates', isDirectory: true),
    assets: getenv('ASSETS_DIR', fallback: 'assets', isDirectory: true),
  );

  return Config(siteConfig, dirConfig);
}
