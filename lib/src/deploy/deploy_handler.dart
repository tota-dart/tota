import 'package:cli_util/cli_logging.dart';

import '../config.dart';
import '../tota_exception.dart';
import 'netlify/netlify_deploy_handler.dart';

/// Types of supported hosting providers.
enum DeployHost { netlify }

/// Handles interactions with a hosting provider to deploy site.
abstract class DeployHandler {
  /// Deploys files from [filesDir] and [functionsDir] to a hosting provider.
  Future<void> deploy(Uri filesDir, {Uri functionsDir, Logger logger});
}

/// Returns the correct deploy handler for the [host].
DeployHandler getDeployHandler(DeployHost host, Config config) {
  switch (host) {
    case DeployHost.netlify:
      var netlifySiteName =
          config.deploy.netlifySite.replaceAll('.netlify.com', '');
      return NetlifyDeployHandler(netlifySiteName, config.deploy.netlifyToken);
    default:
      throw TotaException('deployment method not supported');
  }
}
