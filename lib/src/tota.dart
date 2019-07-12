library tota;

import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:tota/src/deploy/deploy.dart';

import 'config.dart';
import 'exceptions.dart';
import 'file_system.dart' as fs;
import 'resource.dart';
import 'starter.dart';

/// Initializes a new project in [directory].
Future<void> createProject(Uri directory) async {
  var dir = Directory.fromUri(directory);

  // Stop if directory isn't empty.
  if (await dir.exists()) {
    var dirents = await dir.list().toList();
    if (dirents.isNotEmpty) {
      throw TotaIOException(directory.toFilePath(), 'Directory not empty');
    }
  }

  return await clone(directory);
}

/// Creates a new page file.
///
/// The default [type] of resource to create is "page". Will throw an
/// exception if file already exists, but [force] will override this.
Future<void> createPage(ResourceType type, String title,
    {@required Config config, bool force = false, Logger logger}) async {
  logger ??= Logger.standard();

  Progress progress = logger.progress('Generating file');
  Resource page =
      await createResource(type, title, config: config, force: force);
  logger.trace(page.path);
  progress.finish(showTiming: true);
}

/// Compiles source files and generates static files in the public directory.
Future<void> compile(Config config, {Logger logger}) async {
  logger ??= Logger.standard();

  // Empty the public directory.
  logger.stdout('Deleting public directory');
  logger.trace(config.publicDir.toFilePath());
  await fs.removeDirectory(config.publicDir, recursive: true);

  Progress progress = logger.progress('Generating static files');
  await compileResources(ResourceType.page, config: config, logger: logger);
  List<Resource> posts =
      await compileResources(ResourceType.post, config: config, logger: logger);
  progress.finish(showTiming: true);

  // Create posts archive page.
  logger.stdout('Creating archive pages');
  await createPostArchive(
    posts,
    config: config,
    logger: logger,
  );
  await createTagArchives(posts, config: config, logger: logger);

  // Copy assets directory to public directory.
  Uri publicAssetsDir = config.publicDir.resolve(config.assetsPath);
  logger.stdout('Copying assets folder');
  logger.trace(publicAssetsDir.toFilePath());
  fs.copyDirectory(config.assetsDir, publicAssetsDir);
}

/// Deploys site to [host].
Future<void> deploy(DeployHost host,
    {@required Config config, Logger logger}) async {
  DeployHandler handler = createDeployHandler(host, config);
  await handler.deploy(config.publicDir, logger: logger);
}
