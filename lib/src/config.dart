import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'utils.dart';

/// Represents the site configuration settings.
class _SiteConfig {
  _SiteConfig({
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

/// Contains all application configuration settings.
class Config {
  final _SiteConfig site;
  final String rootDir, publicDir, pagesDir, postsDir, templatesDir, assetsDir;

  Config({
    @required this.site,
    @required this.rootDir,
    @required this.publicDir,
    @required this.pagesDir,
    @required this.postsDir,
    @required this.templatesDir,
    @required this.assetsDir,
  });

  /// Resolves a [path] relative to the root directory.
  Uri _resolveDir(String path) => Uri.directory(rootDir).resolve(path);

  /// Resolves a URI to the public directory.
  Uri get publicDirUri => _resolveDir(publicDir);

  /// Resolves a URI to the pages directory.
  Uri get pagesDirUri => _resolveDir(pagesDir);

  /// Resolves a URI to the posts directory.
  Uri get postsDirUri => _resolveDir(postsDir);

  /// Resolves a URI to the templates directory.
  Uri get templatesDirUri => _resolveDir(templatesDir);

  /// Resolves a URI to the assets directory.
  Uri get assetsDirUri => _resolveDir(assetsDir);
}

/// Creates a new config instance from environment variable settings.
Config createConfig(
    {String url,
    title,
    description,
    author,
    language,
    rootDir,
    publicDir,
    pagesDir,
    postsDir,
    templatesDir,
    assetsDir}) {
  var site = _SiteConfig(
    url: url ?? getenv('URL'),
    title: title ?? getenv('TITLE'),
    description: description ?? getenv('DESCRIPTION'),
    author: author ?? getenv('AUTHOR'),
    language: language ?? getenv('LANGUAGE', fallback: 'en'),
  );

  return Config(
    site: site,
    rootDir: rootDir ?? p.current,
    publicDir: publicDir ??
        getenv('PUBLIC_DIR', fallback: 'public', isDirectory: true),
    pagesDir:
        pagesDir ?? getenv('PAGES_DIR', fallback: 'pages', isDirectory: true),
    postsDir:
        postsDir ?? getenv('POSTS_DIR', fallback: 'posts', isDirectory: true),
    templatesDir: templatesDir ??
        getenv('TEMPLATES_DIR', fallback: 'templates', isDirectory: true),
    assetsDir: assetsDir ??
        getenv('ASSETS_DIR', fallback: 'assets', isDirectory: true),
  );
}
