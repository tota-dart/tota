import 'dart:io';
import 'package:slugify/slugify.dart';
import 'package:path/path.dart' as p;
import 'package:mustache/mustache.dart' show Template;
import 'package:meta/meta.dart';
import 'package:cli_util/cli_logging.dart';
import 'file_system.dart' as fs;
import 'utils.dart';
import 'config.dart';

const _markdownFileExtension = '.md';

/// Represents the type of resource.
enum ResourceType { page, post }

/// A resource that was created by the compiler.
class Resource {
  final ResourceType type;
  final DateTime date;
  final String path, title, description, language, author;

  Resource(
      {@required this.type,
      @required this.date,
      @required this.path,
      @required this.title,
      this.description,
      this.language,
      this.author});

  bool get isPage => type == ResourceType.page;

  bool get isPost => type == ResourceType.post;
}

/// Scaffolds a new page file with desired [title].
Future<Resource> createResource(ResourceType type, String title,
    {@required Config config, bool force}) async {
  Uri sourceDir =
      type == ResourceType.post ? config.postsDirUri : config.pagesDirUri;
  // Slugify title to create a file name.
  var filename = p.setExtension(Slugify(title), '.md');
  var uri = sourceDir.resolve(filename);
  var today = DateTime.now();
  var metadata = <String, dynamic>{
    'title': title,
    'date': formatDate(today),
    'template': 'base',
    'public': false,
  };

  await fs.createSourceFile(uri,
      metadata: metadata, content: 'Hello, world!', force: force);

  return Resource(
      type: type, date: today, title: title, path: uri.toFilePath());
}

/// Compiles the files in the pages directory.
Future<List<Resource>> compileResources(ResourceType type,
    {@required Config config, Logger logger}) async {
  var compiled = <Resource>[];
  Uri sourceDir =
      type == ResourceType.post ? config.postsDirUri : config.pagesDirUri;

  /// Lists all Markdown files in the pages directory.
  await for (FileSystemEntity entity
      in fs.listDirectory(sourceDir, recursive: true)) {
    // Only read Markdown files.
    if (entity is! File || p.extension(entity.path) != _markdownFileExtension) {
      continue;
    }

    // Parse source file to retrieve resource content.
    Map<String, dynamic> resource =
        await fs.parseSourceFile(Uri.file(entity.path));

    // Skip files that aren't public.
    if ((resource?.containsKey('public') ?? false) && resource['public']) {
      // Convert body content from Markdown to HTML.
      String content = convertMarkdownToHtml(resource['content']);
      // Load HTML template.
      Template template =
          await fs.loadTemplate(resource['template'], config.templatesDirUri);
      // Accumulate template local variables.
      DateTime date = resource.containsKey('date')
          ? DateTime.parse(resource['date'])
          : DateTime.now();
      Map<String, dynamic> locals = {
        'page': resource,
        'site': config.site.toJson(),
        'content': content,
        'title': resource['title'] ?? config.site.title,
        'description': resource['description'] ?? config.site.description,
        'date': formatDate(date),
        'language': resource['language'] ?? config.site.language,
        'author': resource['author'] ?? config.site.author,
      };

      // Create a sub-directory in public directory for posts.
      // This will be reflected in the URL path for the posts.
      Uri destination = config.publicDirUri
          .resolve(type == ResourceType.post ? config.postsDir : '');

      // Use a relative file path from source directory path to ensure the
      // same nested directory structure is created in the public directory.
      var relativePath = p.relative(entity.path, from: sourceDir.toFilePath());
      // Render template and save generated HTML file.
      var file = await fs.createHtmlFile(Uri.file(relativePath), destination,
          content: template.renderString(locals));

      compiled.add(Resource(
          type: type,
          date: date,
          path: p.relative(p.withoutExtension(file.path),
              from: config.publicDirUri.toFilePath()),
          title: locals['title'],
          description: locals['description'],
          author: locals['author'],
          language: locals['language']));

      if (logger != null) {
        logger.trace(file.path);
      }
    }
  }
  return compiled;
}

/// Creates an archive page for posts.
Future<void> createPostsArchive(List<Resource> posts,
    {@required Config config,
    @required Uri templatesDir,
    @required Uri publicDir}) async {
  if (posts.isEmpty) {
    return;
  }
  Template template = await fs.loadTemplate('archive', templatesDir);
  // Sort posts by date (newest first).
  posts.sort((a, b) => b.date.compareTo(a.date));
  Map<String, dynamic> locals = {
    'site': config.site.toJson(),
    'posts': posts,
    'title': config.site.title,
    'description': config.site.description,
    'author': config.site.author,
    'language': config.site.language,
  };
  Uri publicPostsDir = publicDir.resolve(config.postsDir);
  File file = File.fromUri(publicPostsDir.resolve('index.html'));
  await file.create(recursive: true);
  await file.writeAsString(template.renderString(locals));
}
