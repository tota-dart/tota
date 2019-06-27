import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:mustache/mustache.dart';
import 'tota_exception.dart';
import 'utils.dart';

const _defaultHtmlTemplate = 'base.mustache';

/// Scaffolds a source file from a starting template.
///
/// Creates a new [file] in the source directory with optional [metadata]
/// (front matter) and body [content].
Future<Uri> createSourceFile(Uri fileUri,
    {Map<String, dynamic> metadata,
    String content = '',
    bool force = false}) async {
  File file = File.fromUri(fileUri);
  if (await file.exists()) {
    if (force) {
      // Overwrite file.
      await file.delete();
    } else {
      throw fileAlreadyExistsException(file.path);
    }
  }
  // Prefix content with front matter.
  if (metadata?.isNotEmpty ?? false) {
    content = '${createFrontMatter(metadata)}\n\n$content';
  }
  await file.writeAsString(content);
  return fileUri;
}

/// Lists all files in a [directory] URI.
Stream listDirectory(Uri directory, {bool recursive = false}) {
  var dir = Directory.fromUri(directory);
  if (!dir.existsSync()) {
    throw TotaException('Directory not found: ${directory.toFilePath()}');
  }
  return dir.list(recursive: recursive);
}

/// Parses Markdown file to separate front matter & content.
Future<Map<String, dynamic>> parseSourceFile(Uri fileUri) async {
  try {
    fm.FrontMatterDocument parsed = await fm.parseFile(fileUri.toFilePath());
    final fileMap = Map<String, dynamic>.from(parsed.data);
    fileMap['content'] = parsed.content;
    return fileMap;
  } catch (e) {
    throw TotaException('${e.message} `${fileUri.toFilePath()}`');
  }
}

/// Loads the HTML template.
///
/// If template [filename] is null, defaults to the base template filename.
/// Throws an exception if template file cannot be found in [templatesDir].
Future<Template> loadTemplate(String filename, Uri templatesDir) async {
  // Fallback to default template.
  filename ??= _defaultHtmlTemplate;
  // Add template file extension if absent.
  if (p.extension(filename).isEmpty) {
    filename = p.setExtension(filename, '.mustache');
  }
  // Read template file contents and return template instance.
  var file = File.fromUri(templatesDir.resolve(filename));
  if (!await file.exists()) {
    throw TotaException('HTML template not found: `$filename`');
  }
  var fileContents = await file.readAsString();
  return Template(fileContents,
      partialResolver: partialResolver(templatesDir.resolve('_partials')));
}

/// Saves the generated HTML file in the public directory.
Future<void> createHtmlFile(Uri srcFile, publicDir, {String content}) async {
  var filename = p.setExtension(srcFile.toFilePath(), '.html');
  var file = File.fromUri(publicDir.resolve(filename));
  // Create sub-directories in public directory before writing the file.
  await Directory(p.dirname(file.path)).create(recursive: true);
  // Write content to file.
  await file.writeAsString(content);
}

/// Returns a function that resolves the partial template.
///
/// Recursively searches the `_partials` directory for a file
/// that matches the partial [name].
Function(String name) partialResolver(Uri partialsDir) {
  return (String name) {
    var directory = Directory.fromUri(partialsDir);
    if (!directory.existsSync()) {
      throw TotaException("template partials directory not found");
    }
    var partial = '';
    for (var file in directory.listSync(recursive: true)) {
      if (file is File && p.basenameWithoutExtension(file.path) == name) {
        partial = file.readAsStringSync();
      }
    }
    return Template(partial);
  };
}

/// Copies a directory from a [source] to a [destination] URI.
Future<void> copyDirectory(Uri source, destination) async {
  var sourceDir = Directory.fromUri(source);
  await for (FileSystemEntity entity in sourceDir.list(recursive: true)) {
    if (await FileSystemEntity.isFile(entity.path)) {
      // Relative file path from origin directory.
      var filePath = p.relative(entity.path, from: source.toFilePath());
      // Relative path joined to destination.
      var destPath = p.join(destination.toFilePath(), filePath);
      // Create any nested sub-directories.
      await Directory(p.dirname(destPath)).create(recursive: true);
      // Copy file to new path.
      await File(entity.path).copy(destPath);
    }
  }
}

/// Deletes a [directory].
Future<bool> removeDirectory(Uri directory, {bool recursive = false}) async {
  Directory dir = Directory.fromUri(directory);
  if (await dir.exists()) {
    await dir.delete(recursive: recursive);
  }
  return await dir.exists();
}
