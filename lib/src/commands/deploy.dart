import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/src/deploy/deploy_handler.dart';

import '../../tota.dart' as tota;
import '../config.dart';

class DeployCommand extends Command {
  final name = 'deploy';
  final description = 'Deploy site to hosting provider';

  DeployCommand() {
    argParser.addOption('provider',
        abbr: 'p',
        allowed: ['netlify'],
        help: 'Hosting provider',
        defaultsTo: 'netlify');
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
  }

  void run() async {
    dotenv.load();
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = tota.loadConfig();

      await tota.deploy(_parseProvider(argResults['provider']),
          config: config, logger: logger);

      logger.stdout('Project ${logger.ansi.emphasized('deployed')}.');
    } catch (e) {
      switch (e.runtimeType) {
        case tota.TotaException:
          logger.stderr(logger.ansi.error(e.message));
          break;
        default:
          rethrow;
      }
    }
  }
}

DeployHost _parseProvider(String provider) {
  switch (provider) {
    case 'netlify':
      return DeployHost.netlify;
    default:
      throw tota.TotaException('host not supported: `$provider`');
  }
}
