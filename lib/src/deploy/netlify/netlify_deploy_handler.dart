import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

import '../deploy_handler.dart';
import 'netlify_deploy.dart';
import 'netlify_file.dart';
import 'netlify_site.dart';

/// Base URI for Netlify API.
final Uri baseUri = Uri.parse('https://api.netlify.com/api/v1/');

/// Default headers with JSON content type.
final Map<String, String> defaultHeaders = {
  HttpHeaders.contentTypeHeader: 'application/json'
};

/// Deploys a site to Netlify.
class NetlifyDeployHandler implements DeployHandler {
  final String siteName, accessToken;

  NetlifyDeployHandler(this.siteName, this.accessToken);

  /// Builds a list of files in a [directory] with digests.
  Future<List<NetlifyFile>> _createDigest(Uri directory,
      {Logger logger}) async {
    logger ??= Logger.standard();
    var files = <NetlifyFile>[];
    await for (FileSystemEntity entity
        in Directory.fromUri(directory).list(recursive: true)) {
      if (entity is File) {
        NetlifyFile file = NetlifyFile(
            directory, p.relative(entity.path, from: directory.toFilePath()));
        await file.createDigest();
        files.add(file);
        logger.trace(directory.resolve(file.path).toFilePath());
      }
    }
    return files;
  }

  /// Deploys the site to Netlify.
  ///
  /// Sends a digest of all files to Netlify to be uploaded,
  /// then uploads whatever Netlify doesn't have on its server.
  @override
  Future<void> deploy(Uri filesDir, {Uri functionsDir, Logger logger}) async {
    logger ??= Logger.standard();

    // Create a digest of files to be uploaded.
    Progress digestProgress = logger.progress('Gathering file information');
    List<NetlifyFile> files = await _createDigest(filesDir, logger: logger);
    List<NetlifyFile> functions = [];
    if (functionsDir != null) {
      functions.addAll(await _createDigest(functionsDir));
    }
    digestProgress.finish(showTiming: true);

    // Find or create the site.
    Progress siteProgress = logger.progress('Looking for Netlify site');
    NetlifySite site =
        await NetlifySite.findOrCreate(siteName, accessToken, logger: logger);
    siteProgress.finish(showTiming: true);

    // Create a deploy from file digests.
    Progress deployProgress = logger.progress('Creating deployment');
    NetlifyDeploy deploy = NetlifyDeploy.from(files, functions);
    await deploy.create(site, accessToken, logger: logger);
    deployProgress.finish(showTiming: true);

    // Skip files that are already on Netlify's servers.
    files.retainWhere(
        (file) => deploy.requiredFiles.contains(file.digest.toString()));
    if (deploy.hasFunctions) {
      functions.retainWhere(
          (file) => deploy.requiredFunctions.contains(file.digest.toString()));
    }

    Progress uploadProgress = logger.progress('Uploading files');
    var filesUploaded =
        await deploy.uploadAll(files, accessToken, logger: logger);

    logger.trace(filesUploaded.isEmpty
        ? 'No new files to upload.'
        : 'Uploaded ${filesUploaded.length} file(s).');
    uploadProgress.finish(showTiming: true);
  }
}
