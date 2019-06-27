import 'dart:io';
import 'package:slugify/slugify.dart';
import 'package:path/path.dart' as p;
import 'package:mustache/mustache.dart' show Template;
import 'package:meta/meta.dart';
import 'fs.dart' as fs;
import 'utils.dart';
import 'config.dart';

const _markdownFileExtension = '.md';

/// Represents the type of resource.
enum ResourceType { page, post }

/// A resource that was created by the compiler.
class Resource {
  final DateTime date;
  final String url, title, description, language, author;

  Resource(
      {@required this.url,
      @required this.title,
      @required this.date,
      this.description,
      this.language,
      this.author});
}

/// Scaffolds a new page file with desired [title].
Future<Uri> createResource(Uri sourceDir, String title, {bool force}) async {
  // Slugify title to create a file name.
  var fileName = p.setExtension(Slugify(title), '.md');
  var metadata = <String, dynamic>{
    'title': title,
    'date': formatDate(DateTime.now()),
    'template': 'base',
    'public': false,
  };

  return fs.createSourceFile(sourceDir.resolve(fileName),
      metadata: metadata, content: 'Hello, world!', force: force);
}

/// Compiles the files in the pages directory.
Future<List<Resource>> compileResources(
    {@required Uri sourceDir,
    @required Uri publicDir,
    @required Uri templatesDir,
    @required Config config,
    ResourceType resourceType}) async {
  var compiled = <Resource>[];

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
          await fs.loadTemplate(resource['template'], templatesDir);
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

      // Calculate sub-directory destination within the public directory.
      Uri destinationUri;
      switch (resourceType) {
        case ResourceType.post:
          destinationUri = publicDir.resolve(config.dir.posts);
          break;
        default:
          destinationUri = publicDir;
      }

      // Use a relative file path from source directory path to ensure the
      // same nested directory structure is created in the public directory.
      var relativePath = p.relative(entity.path, from: sourceDir.toFilePath());
      // Render template and save generated HTML file.
      var file = await fs.createHtmlFile(Uri.file(relativePath), destinationUri,
          content: template.renderString(locals));

      compiled.add(Resource(
          date: date,
          url: p.relative(p.withoutExtension(file.path),
              from: publicDir.toFilePath()),
          title: locals['title'],
          description: locals['description'],
          author: locals['author'],
          language: locals['language']));
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
  Uri publicPostsDir = publicDir.resolve(config.dir.posts);
  File file = File.fromUri(publicPostsDir.resolve('index.html'));
  await file.create(recursive: true);
  await file.writeAsString(template.renderString(locals));
}
