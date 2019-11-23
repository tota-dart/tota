import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:mustache/mustache.dart';
import 'package:tota/src/exceptions.dart';

import '../../tota.dart';
import '../config.dart';

class BuildCommand extends Command {
  @override
  final name = 'build';

  @override
  final description = 'Generate static files.';

  BuildCommand() {
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
  }

  @override
  void run() async {
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = Config.fromEnv();
      await compile(config, logger: logger);

      logger.stdout('All ${logger.ansi.emphasized('done')}.');
    } on TemplateException catch (e) {
      logger.stderr(logger.ansi.error('Failed to render template'));
      logger.stderr(logger.ansi.error(e.toString()));
    } on TotaIOException catch (e) {
      logger.stderr(logger.ansi.error('${e.message}: ${e.path}'));
    } on TotaException catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    } catch (e) {
      rethrow;
    }
  }
}
