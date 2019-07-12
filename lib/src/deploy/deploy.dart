import 'package:cli_util/cli_logging.dart';

import '../config.dart';
import '../exceptions.dart';
import 'netlify/netlify_client.dart';
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
        NetlifyClient client = NetlifyClient(
            config.netlifySite.replaceAll('.netlify.com', ''),
            config.netlifyToken);
        return NetlifyDeployHandler(client);
      }
    default:
      throw TotaException('deployment method not supported');
  }
}
