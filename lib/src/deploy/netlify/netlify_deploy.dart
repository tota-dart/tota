import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../../tota_exception.dart';
import 'netlify_config.dart';
import 'netlify_deploy_handler.dart';
import 'netlify_file.dart';

const String _deployTitle = 'Deploy via Tota CLI';

/// Pool for async HTTP requests.
///
/// Specifies number of concurrent HTTP requests, to avoid attacking Netlify's API.
final Pool _pool = Pool(15);

/// A Netlify deploy resource.
class NetlifyDeploy {
  final NetlifyConfig config;

  /// Static files to be uploaded.
  final List<NetlifyFile> files;

  /// Netlify lambda funcitons to be uploaded.
  final List<NetlifyFile> functions;

  /// Deploy ID returned when creating a new deploy.
  String deployId;

  /// List of digests of files/functions Netlify doesn't have on its servers.
  List<String> requiredFiles, requiredFunctions;

  NetlifyDeploy({@required this.config, this.files, this.functions});

  /// Has created a successful deployment resource.
  bool get hasId => deployId != null;

  /// Truthy if Netlify expects functions to be uploaded.
  bool get hasFunctions => requiredFunctions != null;

  /// Netlify API expects a Map of file path => digest.
  Map<String, dynamic> toJson() {
    var data = {
      // Add a note to the deploy message about the origin of this deploy.
      'title': _deployTitle,
      'files': Map.fromIterable(files,
          // File path requires a leading slash.
          key: (file) => '/${file.path}',
          value: (file) => file.digest.toString()),
    };
    if (functions.isNotEmpty) {
      data['functions'] = Map.fromIterable(functions,
          key: (file) => file.path, value: (file) => file.digest.toString());
    }
    return data;
  }

  /// Creates a new deploy with the Netlify API.
  Future<void> create({Logger logger}) async {
    logger ??= Logger.standard();
    var response = await post(
        config.baseUri.resolve(
            'sites/${config.siteId}/deploys?access_token=${config.accessToken}'),
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

  /// Uploads a single [file] to Netlify.
  ///
  /// Adds file upload to the upload pool to throttle requests to API.
  Future<NetlifyFile> _uploadSingle(NetlifyFile file, {Logger logger}) async {
    return _pool.withResource(() => file.upload(deployId, logger: logger));
  }

  /// Uploads all [files] to Netlify.
  Future<List<NetlifyFile>> uploadAll(List<NetlifyFile> files,
      {Logger logger}) async {
    if (!hasId) {
      throw TotaException('[netlify] deploy ID not set');
    }
    return await Future.wait(
        files.map((file) => _uploadSingle(file, logger: logger)));
  }
}
