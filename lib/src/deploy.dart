import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

import '../../tota.dart' as tota;

class InitCommand extends Command {
  final name = 'init';
  final description = 'Create a new Tota project.';

  InitCommand() {
    argParser.addOption('directory',
        defaultsTo: '.', abbr: 'd', help: 'Directory path.');
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
  }

  void run() async {
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      String directoryPath = argResults['directory'] == '.'
          ? p.current
          : p.join(p.current, argResults['directory']);

      Progress progress = logger.progress('Intializing project');
      await tota.createProject(Uri.directory(directoryPath));
      progress.finish(showTiming: true);

      logger.stdout('Project ${logger.ansi.emphasized('created')}.');
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}
