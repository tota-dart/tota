import '../config.dart';
import '../tota_exception.dart';
import 'netlify_deploy_handler.dart';

enum HostProvider { netlify }

/// Interface to handle deploys.
abstract class DeployHandler {
  /// Deploys a [directory] to host.
  Future<void> deploy(Uri directory);
}

DeployHandler getDeployHandler(HostProvider host, Config config) {
  switch (host) {
    case HostProvider.netlify:
      return NetlifyDeployHandler(
          config.deploy.netlifySite, config.deploy.netlifyToken);
    default:
      throw TotaException('deployment method not supported');
  }
}
