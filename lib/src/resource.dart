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

/// A resource that was created by the compiler.
class Resource {
  String title, description, date, language, author;

  Resource(
      {@required this.title,
      this.description,
      this.date,
      this.language,
      this.author});

  Map<String, String> toJson() {
    return <String, String>{
      'title': title,
      'description': description,
      'date': date,
      'language': language,
      'author': author,
    };
  }
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
      // Accumulate template variables.
      Map<String, dynamic> templateLocals = {
        'page': resource,
        'site': config.site.toJson(),
        'content': content,
        'title': resource['title'] ?? config.site.title,
        'description': resource['description'] ?? config.site.description,
        'date': resource['date'] ?? formatDate(DateTime.now()),
        'language': resource['language'] ?? config.site.language,
        'author': resource['author'] ?? config.site.author,
      };

      // Use a relative file path from source directory path to ensure the
      // same nested directory structure is created in the public directory.
      var relativePath = p.relative(entity.path, from: sourceDir.toFilePath());
      // Render template and save generated HTML file.
      await fs.createHtmlFile(Uri.file(relativePath), publicDir,
          content: template.renderString(templateLocals));

      compiled.add(Resource(
          title: templateLocals['title'],
          description: templateLocals['description'],
          date: templateLocals['date'],
          author: templateLocals['author'],
          language: templateLocals['language']));
    }
  }
  return compiled;
}
