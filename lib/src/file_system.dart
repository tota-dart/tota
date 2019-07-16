import 'dart:io';

import 'package:front_matter/front_matter.dart' as fm;
import 'package:mustache/mustache.dart';
import 'package:path/path.dart' as p;

import 'exceptions.dart';
import 'utils.dart';

/// Scaffolds a source file from a starting template.
///
/// Creates a new [file] in the source directory with optional [metadata]
/// (front matter) and body [content].
Future<Uri> createSourceFile(Uri uri,
    {Map<String, dynamic> metadata, String content = '', bool force}) async {
  force ??= false;
  File file = File.fromUri(uri);
  if (await file.exists()) {
    if (force) {
      // Overwrite file.
      await file.delete();
    } else {
      throw TotaIOException(file.path, 'File already exists');
    }
  }
  // Prefix content with front matter.
  if (metadata?.isNotEmpty ?? false) {
    content = '${createFrontMatter(metadata)}\n\n$content';
  }
  await file.writeAsString(content);
  return uri;
}

/// Lists all files in a [directory] URI.
Stream listDirectory(Uri directory, {bool recursive = false}) {
  var dir = Directory.fromUri(directory);
  if (!dir.existsSync()) {
    throw TotaIOException(directory.toFilePath(), 'Directory not found');
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
    throw TotaIOException(fileUri.toFilePath(), 'Unable to parse file');
  }
}

/// Loads the HTML template from [path] in a [directory].
Future<Template> loadTemplate(String path, Uri directory) async {
  // Append template file extension if absent.
  if (p.extension(path).isEmpty) {
    path = p.setExtension(path, '.mustache');
  }
  // Read template file contents and return template instance.
  var file = File.fromUri(directory.resolve(path));
  if (!await file.exists()) {
    throw TotaIOException(file.path, 'Template not found');
  }
  String content = await file.readAsString();
  return Template(content,
      partialResolver: createPartialResolver(directory.resolve('_partials')));
}

/// Saves the generated HTML file in the public directory.
Future<File> createHtmlFile(Uri srcFile, publicDir, {String content}) async {
  var filename = p.setExtension(srcFile.toFilePath(), '.html');
  var file = File.fromUri(publicDir.resolve(filename));
  // Create sub-directories in public directory before writing the file.
  await Directory(p.dirname(file.path)).create(recursive: true);
  // Write content to file.
  return await file.writeAsString(content);
}

/// Returns a function that resolves the partial template.
///
/// Recursively searches the `_partials` directory for a file
/// that matches the partial [name].
Function(String name) createPartialResolver(Uri partialsDir) {
  return (String name) {
    var directory = Directory.fromUri(partialsDir);
    if (!directory.existsSync()) {
      throw TotaIOException(directory.path, 'Partials directory not found');
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
