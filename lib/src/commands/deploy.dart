import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/src/deploy/deploy_handler.dart';

import '../../tota.dart';
import '../config.dart';

class DeployCommand extends Command {
  @override
  final name = 'deploy';

  @override
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

  @override
  void run() async {
    dotenv.load();
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = Config.fromEnv();

      await deploy(_parseProvider(argResults['provider']),
          config: config, logger: logger);

      logger.stdout('Site ${logger.ansi.emphasized('deployed')}.');
    } on TotaException catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    } catch (e) {
      rethrow;
    }
  }
}

/// Parses [provider] and returns a valid deploy host.
DeployHost _parseProvider(String provider) {
  switch (provider) {
    case 'netlify':
      return DeployHost.netlify;
    default:
      throw TotaException('host not supported: `$provider`');
  }
}
