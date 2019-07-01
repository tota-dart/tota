import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart';
import 'package:pool/pool.dart';
import 'package:tota/src/deploy/netlify/netlify_deploy_handler.dart';
import 'package:tota/src/tota_exception.dart';

import 'netlify_file.dart';
import 'netlify_site.dart';

/// Pool for async HTTP requests.
///
/// Specifies number of concurrent HTTP requests, to avoid attacking Netlify's API.
final Pool _pool = Pool(15);

/// A Netlify deploy resource.
class NetlifyDeploy {
  final List<NetlifyFile> files;
  final List<NetlifyFile> functions;

  /// Deploy ID returned when creating a new deploy.
  String deployId;

  /// List of digests of files/functions to be uploaded to Netlify.
  List<String> requiredFiles, requiredFunctions;

  NetlifyDeploy(this.files, this.functions);

  /// Has created a successful deployment resource.
  bool get hasId => deployId != null;

  /// Truthy if Netlify expects functions to be uploaded.
  bool get hasFunctions => requiredFunctions != null;

  /// Netlify API expects a Map of file path => digest.
  Map<String, dynamic> toJson() {
    var data = {
      // Add a note to the deploy message about the origin of this deploy.
      'title': 'Deploy via Tota CLI',
      'files': Map.fromIterable(files,
          // File path requires a leading slash.
          key: (item) => '/${item.path}',
          value: (item) => item.digest.toString()),
    };
    if (functions.isNotEmpty) {
      data['functions'] = Map.fromIterable(functions,
          key: (item) => item.path, value: (item) => item.digest.toString());
    }
    return data;
  }

  /// Creates a new deploy with the Netlify API.
  Future<void> create(NetlifySite site, String accessToken,
      {Logger logger}) async {
    logger ??= Logger.standard();
    var response = await post(
        baseUri
            .resolve('sites/${site.siteId}/deploys?access_token=$accessToken'),
        body: json.encode(toJson()),
        headers: defaultHeaders);
    var body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw TotaException('[netlify] failed to create deploy');
    }
    this.deployId = body['id'];
    this.requiredFiles = List<String>.from(body['required']);
    if (body['required_functions'] != null) {
      this.requiredFunctions = List<String>.from(body['required_functions']);
    }
    logger.trace('Deploy created with ID: $deployId');
  }

  /// Creates a new Netlify deployment from [files] and [functions].
  NetlifyDeploy.from(List<NetlifyFile> files, functions)
      : files = files,
        functions = functions;

  /// Uploads a single [file] to Netlify.
  ///
  /// Adds file upload to the upload pool to throttle requests to API.
  Future<NetlifyFile> _uploadSingle(NetlifyFile file, String accessToken,
      {Logger logger}) async {
    return _pool
        .withResource(() => file.upload(deployId, accessToken, logger: logger));
  }

  /// Uploads all [files] to Netlify.
  Future<List<NetlifyFile>> uploadAll(
      List<NetlifyFile> files, String accessToken,
      {Logger logger}) async {
    if (!hasId) {
      throw TotaException('[netlify] deploy ID not set');
    }
    return await Future.wait(
        files.map((file) => _uploadSingle(file, accessToken, logger: logger)));
  }
}
