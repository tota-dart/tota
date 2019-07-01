import 'package:cli_util/cli_logging.dart';

import '../config.dart';
import '../tota_exception.dart';
import 'netlify/netlify_deploy_handler.dart';

enum HostProvider { netlify }

/// Interface to handle deploys.
abstract class DeployHandler {
  /// Deploys files from [filesDir] and [functionsDir] to Netlify.
  Future<void> deploy(Uri filesDir, {Uri functionsDir, Logger logger});
}

DeployHandler getDeployHandler(HostProvider host, Config config) {
  switch (host) {
    case HostProvider.netlify:
      var netlifySiteName =
          config.deploy.netlifySite.replaceAll('.netlify.com', '');
      return NetlifyDeployHandler(netlifySiteName, config.deploy.netlifyToken);
    default:
      throw TotaException('deployment method not supported');
  }
}
