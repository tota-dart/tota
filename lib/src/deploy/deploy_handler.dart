import 'package:cli_util/cli_logging.dart';

import '../config.dart';
import '../tota_exception.dart';
import 'netlify/netlify_deploy_handler.dart';

/// Indicates the deployment hosting provider.
enum DeployHost { netlify }

/// Handles interactions with a hosting provider to deploy a site.
abstract class DeployHandler {
  /// Deploys files from [filesDir] and [functionsDir] to a hosting provider.
  Future<void> deploy(Uri filesDir, {Uri functionsDir, Logger logger});
}

/// Creates a deploy handler for the [host].
DeployHandler createDeployHandler(DeployHost host, Config config) {
  switch (host) {
    case DeployHost.netlify:
      {
        var siteName = config.netlifySite.replaceAll('.netlify.com', '');
        return NetlifyDeployHandler(
            siteName: siteName, accessToken: config.netlifyToken);
      }
    default:
      throw TotaException('deployment method not supported');
  }
}
