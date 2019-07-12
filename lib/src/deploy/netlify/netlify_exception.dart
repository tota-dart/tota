import '../../exceptions.dart';
import '../deploy.dart';

class NetlifyException extends DeployException {
  final int statusCode;

  NetlifyException(String message, [this.statusCode])
      : super(DeployHost.netlify, message);
}
