import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:tota/src/deploy/netlify/netlify_deploy_handler.dart';
import 'package:tota/src/tota_exception.dart';

/// deploys/1234/files/index.html

/// A file to be uploaded to Netlify.
///
/// Contains a digest of file path and SHA1 of file contents.
class NetlifyFile {
  /// URI of containing [directory].
  final Uri directory;

  /// File [path] within [directory].
  final String path;

  /// SHA1 [digest] of file contents;
  Digest digest;

  NetlifyFile(this.directory, this.path);

  /// Reads the file as bytes.
  Future<List<int>> _readAsBytes() async {
    return await File.fromUri(directory.resolve(path)).readAsBytes();
  }

  /// Creates SHA1 digest of file contents.
  Future<void> createDigest() async {
    List<int> bytes = await _readAsBytes();
    this.digest = sha1.convert(bytes);
  }

  /// Uploads the file to Netlify.
  Future<NetlifyFile> upload(String deployId, accessToken,
      {Logger logger}) async {
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/octet-stream'
    };
    logger ??= Logger.standard();
    var response = await put(
        baseUri
            .resolve('deploys/$deployId/files/$path?access_token=$accessToken'),
        headers: headers,
        body: await _readAsBytes());

    var body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw TotaException("Failed to upload file `$path`: ${body['message']}");
    }
    logger.trace(directory.resolve(path).toFilePath());
    return this;
  }
}
