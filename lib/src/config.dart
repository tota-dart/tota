import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

/// Contains all project configuration settings.
class Config {
  /// Configuration settings for directory paths.
  final String rootPath,
      publicPath,
      pagesPath,
      postsPath,
      templatesPath,
      assetsPath;

  /// Configuration settings for the site.
  final String url, title, description, author, language;

  /// Configuration settings for posts
  final String permalink, dateFormat;

  /// Configuration settings for deployment.
  final String netlifySite, netlifyToken;

  Config({
    @required this.rootPath,
    @required this.publicPath,
    @required this.pagesPath,
    @required this.postsPath,
    @required this.templatesPath,
    @required this.assetsPath,
    @required this.url,
    @required this.title,
    @required this.description,
    @required this.author,
    @required this.language,
    @required this.dateFormat,
    this.permalink,
    this.netlifySite,
    this.netlifyToken,
  });

  /// Loads configuration from environment variables.
  Config.fromEnv({String rootPath})
      : rootPath = rootPath ?? p.current,
        publicPath =
            getenv('PUBLIC_DIR', fallback: 'public', isDirectory: true),
        pagesPath = getenv('PAGES_DIR', fallback: 'pages', isDirectory: true),
        postsPath = getenv('POSTS_DIR', fallback: 'posts', isDirectory: true),
        templatesPath =
            getenv('TEMPLATES_DIR', fallback: 'templates', isDirectory: true),
        assetsPath =
            getenv('ASSETS_DIR', fallback: 'assets', isDirectory: true),
        url = getenv('URL'),
        title = getenv('TITLE'),
        description = getenv('DESCRIPTION'),
        author = getenv('AUTHOR'),
        language = getenv('LANGUAGE', fallback: 'en'),
        dateFormat = getenv('DATE_FORMAT', fallback: 'YYYY-MM-DD'),
        permalink = getenv('PERMALINK', isRequired: false),
        netlifySite = getenv('NETLIFY_SITE', isRequired: false),
        netlifyToken = getenv('NETLIFY_TOKEN', isRequired: false);

  /// Resolves a [path] relative to the root directory.
  Uri _resolveDir(String path) => Uri.directory(rootPath).resolve(path);

  /// Resolves a URI to the public directory.
  Uri get publicDir => _resolveDir(publicPath);

  /// Resolves a URI to the pages directory.
  Uri get pagesDir => _resolveDir(pagesPath);

  /// Resolves a URI to the posts directory.
  Uri get postsDir => _resolveDir(postsPath);

  /// Resolves a URI to the templates directory.
  Uri get templatesDir => _resolveDir(templatesPath);

  /// Resolves a URI to the assets directory.
  Uri get assetsDir => _resolveDir(assetsPath);

  /// Returns a JSON map of site configuration settings.
  Map<String, String> siteJson() => <String, String>{
        'url': url,
        'title': title,
        'description': description,
        'author': author,
        'language': language
      };
}
