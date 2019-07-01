import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

/// Configuration settings for the site.
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

/// Configuration settings for posts.
class _PostsConfig {
  final String permalink;
  final String dateFormat;

  _PostsConfig({@required this.dateFormat, this.permalink});
}

/// Configuration settings for deployment.
class _DeployConfig {
  final String netlifySite, netlifyToken;

  _DeployConfig({this.netlifySite, this.netlifyToken});
}

/// Contains all application configuration settings.
class Config {
  final _SiteConfig site;
  final _PostsConfig posts;
  final _DeployConfig deploy;
  final String rootDir, publicDir, pagesDir, postsDir, templatesDir, assetsDir;

  Config({
    @required this.site,
    @required this.posts,
    @required this.deploy,
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

/// Creates config from supplied parameters.
Config createConfig({
  String url,
  title,
  description,
  author,
  language,
  rootDir,
  publicDir,
  pagesDir,
  postsDir,
  templatesDir,
  assetsDir,
  dateFormat,
  permalink,
  netlifySite,
  netlifyToken,
}) =>
    Config(
        site: _SiteConfig(
            url: url,
            title: title,
            description: description,
            author: author,
            language: language),
        posts: _PostsConfig(dateFormat: dateFormat, permalink: permalink),
        deploy:
            _DeployConfig(netlifySite: netlifySite, netlifyToken: netlifyToken),
        rootDir: rootDir,
        publicDir: publicDir,
        pagesDir: pagesDir,
        postsDir: postsDir,
        templatesDir: templatesDir,
        assetsDir: assetsDir);

/// Loads config from environment variable values.
Config loadConfig() => createConfig(
      url: getenv('URL'),
      title: getenv('TITLE'),
      description: getenv('DESCRIPTION'),
      author: getenv('AUTHOR'),
      language: getenv('LANGUAGE', fallback: 'en'),
      rootDir: p.current,
      publicDir: getenv('PUBLIC_DIR', fallback: 'public', isDirectory: true),
      pagesDir: getenv('PAGES_DIR', fallback: 'pages', isDirectory: true),
      postsDir: getenv('POSTS_DIR', fallback: 'posts', isDirectory: true),
      templatesDir:
          getenv('TEMPLATES_DIR', fallback: 'templates', isDirectory: true),
      assetsDir: getenv('ASSETS_DIR', fallback: 'assets', isDirectory: true),
      dateFormat: getenv('DATE_FORMAT', fallback: 'YYYY-MM-DD'),
      permalink: getenv('PERMALINK', isRequired: false),
      netlifySite: getenv('NETLIFY_SITE', isRequired: false),
      netlifyToken: getenv('NETLIFY_TOKEN', isRequired: false),
    );
