import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../tota.dart';
import '../config.dart';
import '../exceptions.dart';

class NewCommand extends Command {
  @override
  final name = 'new';

  @override
  final description = 'Create a new page.';

  NewCommand() {
    argParser.addOption('type',
        allowed: ['page', 'post'],
        defaultsTo: 'pages',
        abbr: 't',
        help: 'Type of page to create.');
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
    argParser.addFlag('force',
        abbr: 'f',
        negatable: false,
        help: 'Force creation of file.',
        defaultsTo: false);
  }

  @override
  void run() async {
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = Config.fromEnv();

      String title = argResults.rest.isEmpty ? '' : argResults.rest[0];
      if (title.isEmpty) {
        throw TotaException('Title is required');
      }

      await createPage(
        _parseResourceType(argResults['type']),
        title,
        config: config,
        force: argResults['force'],
        logger: logger,
      );

      logger.stdout('File ${logger.ansi.emphasized('created')}.');
    } on TotaIOException catch (e) {
      logger.stderr(logger.ansi.error('${e.message}: ${e.path}'));
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}

/// Parses page [type] and returns a valid resource type.
ResourceType _parseResourceType(String type) {
  switch (type) {
    case 'post':
      return ResourceType.post;
    default:
      return ResourceType.page;
  }
}
