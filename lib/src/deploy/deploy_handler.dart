/*
import 'netlify_deploy_handler.dart';
import '../tota_exception.dart';

enum DeployType { netlify }

abstract class DeployHandler {
  void Deploy(Uri directory);
}

DeployHandler getDeployHandler(DeployType type) {
  switch (type) {
    case DeployType.netlify:
      return NetlifyDeployHandler;
    default:
      throw TotaException('deployment method not supported');
  }
}
*/
