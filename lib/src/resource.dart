import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart' show Template;
import 'package:mustache/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:slugify/slugify.dart';
import 'package:tota/src/exceptions.dart';

import 'config.dart';
import 'file_system.dart' as fs;
import 'utils.dart';

const _markdownFileExtension = '.md';
const _mustacheFileExtension = '.mustache';
const _defaultHtmlTemplate = 'base$_mustacheFileExtension';

/// Represents the type of resource.
enum ResourceType { page, post }

/// A resource that was created by the compiler.
class Resource {
  final ResourceType type;
  final DateTime date;
  final String path, title, description, language, author;
  final List<String> _tags = [];

  Resource({
    @required this.type,
    @required this.date,
    @required this.path,
    @required this.title,
    this.description,
    this.language,
    this.author,
    List<String> tags,
  }) {
    if (tags != null) {
      _tags.addAll(tags);
    }
  }

  List<String> get tags => _tags;

  bool get isPage => type == ResourceType.page;

  bool get isPost => type == ResourceType.post;
}

/// Scaffolds a new page file with desired [title].
Future<Resource> createResource(
  ResourceType type,
  String title, {
  @required Config config,
  bool force,
}) async {
  Uri sourceDir = type == ResourceType.post ? config.postsDir : config.pagesDir;
  // Slugify title to create a file name.
  var filename = p.setExtension(Slugify(title), '.md');
  var uri = sourceDir.resolve(filename);
  var today = DateTime.now();
  var metadata = <String, dynamic>{
    'title': title,
    'date': DateFormat('yyyy-MM-dd').format(today),
    'template': 'base',
    'public': false,
  };

  await fs.createSourceFile(uri,
      metadata: metadata, content: 'Hello, world!', force: force);

  return Resource(
      type: type, date: today, title: title, path: uri.toFilePath());
}

/// Compiles the files in the pages directory.
Future<List<Resource>> compileResources(
  ResourceType type, {
  @required Config config,
  Logger logger,
}) async {
  var compiled = <Resource>[];
  Uri sourceDir = type == ResourceType.post ? config.postsDir : config.pagesDir;

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
      Template template = await _resolveTemplate(
          resource['template'], config.templatesDir,
          fallback: _resolveTemplateForType(type, config));
      // Accumulate template local variables.
      DateTime date = resource.containsKey('date')
          ? DateTime.parse(resource['date'])
          : DateTime.now();
      Map<String, dynamic> locals = {
        'page': resource,
        'site': config.siteJson(),
        'content': content,
        'title': resource['title'] ?? config.title,
        'description': resource['description'] ?? config.description,
        'date': DateFormat(config.dateFormat).format(date),
        'language': resource['language'] ?? config.language,
        'author': resource['author'] ?? config.author,
      };

      // Create a sub-directory in public directory for posts.
      // This will be reflected in the URL path for the posts.
      Uri destination = config.publicDir
          .resolve(type == ResourceType.post ? config.postsPath : '');

      // Use a relative file path from source directory path to ensure the
      // same nested directory structure is created in the public directory.
      var relativePath = p.relative(entity.path, from: sourceDir.toFilePath());
      // Render template and save generated HTML file.
      var file = await fs.createHtmlFile(Uri.file(relativePath), destination,
          content: template.renderString(locals));

      // Create a list of tags.
      List<String> tags;
      if (resource['tags'] is List) {
        tags = List<String>.from(resource['tags']);
      }

      var publicPath = p.relative(p.withoutExtension(file.path),
          from: config.publicDir.toFilePath());
      compiled.add(Resource(
        type: type,
        date: date,
        path: '/$publicPath',
        title: locals['title'],
        description: locals['description'],
        author: locals['author'],
        language: locals['language'],
        tags: tags,
      ));

      if (logger != null) {
        logger.trace(file.path);
      }
    }
  }
  return compiled;
}

// Creates an archive file from list of posts.
Future<File> _createArchiveFile(
  Uri uri,
  List<Resource> posts, {
  @required Config config,
  Logger logger,
  String tag,
}) async {
  // Create template locals.
  Map<String, dynamic> locals = {
    'site': config.siteJson(),
    'posts': posts,
    'title': tag ?? config.title,
    'description': config.description,
    'author': config.author,
    'language': config.language,
  };
  // Load template.
  Template template = await fs.loadTemplate('archive', config.templatesDir);
  // Save file.
  File file = File.fromUri(uri);
  await file.create(recursive: true);
  await file.writeAsString(template.renderString(locals));
  if (logger != null) {
    logger.trace(file.path);
  }
  return file;
}

/// Resolves the default template for resource [type].
///
/// Default file is inferred to be a mustache file in the templates
/// directory with the same filename as the source posts directory.
String _resolveTemplateForType(ResourceType type, Config config) {
  switch (type) {
    case ResourceType.post:
      return p.setExtension(
          p.basenameWithoutExtension(config.postsPath), _mustacheFileExtension);
    default:
      return p.setExtension(
          p.basenameWithoutExtension(config.pagesPath), _mustacheFileExtension);
  }
}

///  Retrieves the template from [path] in [directory].
///
/// If [template] is not found, tries to load the [fallback] template,
/// before eventually loading the base template as last resort.
Future<Template> _resolveTemplate(
  String path,
  Uri directory, {
  String fallback,
}) async {
  for (var file in <String>[path, fallback]) {
    try {
      if (file != null) {
        return await fs.loadTemplate(file, directory);
      }
    } on TotaIOException {
      // Load the next file in list if file not found.
      continue;
    } catch (e) {
      rethrow;
    }
  }
  return fs.loadTemplate(_defaultHtmlTemplate, directory);
}

/// Creates a posts archive page.
Future<void> createPostArchive(
  List<Resource> posts, {
  @required Config config,
  Logger logger,
}) async {
  if (posts.isEmpty) {
    return;
  }
  // Sort resources by date (newest first).
  posts.sort((a, b) => b.date.compareTo(a.date));

  // Create the archive page in the posts public directory.
  Uri publicPostsDir = config.publicDir.resolve(config.postsPath);
  await _createArchiveFile(
    publicPostsDir.resolve('index.html'),
    posts,
    config: config,
    logger: logger,
  );
}

/// Creates archive pages for all tags used.
Future<void> createTagArchives(
  List<Resource> resources, {
  @required config,
  Logger logger,
}) async {
  Set<String> tags = resources
      .map((resource) => resource.tags)
      .expand((tags) => tags)
      .map((tag) => tag.toLowerCase())
      .toSet();

  for (var tag in tags) {
    // Get posts that contain tag.
    var posts =
        resources.where((resource) => resource.tags.contains(tag)).toList();
    // Sort posts by date (newest first).
    posts.sort((a, b) => a.date.compareTo(b.date));
    var tagUri = config.publicDir.resolve('tags/$tag.html');
    await _createArchiveFile(
      tagUri,
      posts,
      config: config,
      logger: logger,
      tag: tag,
    );
  }
}
