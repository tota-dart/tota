import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:cli_util/cli_logging.dart';
import '../../tota.dart' as tota;
import '../utils.dart';

class BuildCommand extends Command {
  final name = 'build';
  final description = 'Generates static files.';

  BuildCommand() {
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
    argParser.addFlag('deploy',
        abbr: 'd', negatable: false, help: 'Deploy after build finishes.');
  }

  void run() async {
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      // Delete existing public directory.
      var publicDir = Directory(p.join(p.current, getenv('PUBLIC_DIR')));
      if (await publicDir.exists()) {
        await publicDir.delete(recursive: true);
      }

      Progress buildProgress = logger.progress('Generating static files');
      List<Uri> files = await tota.build();
      files.forEach((file) => logger.trace(file.path));
      buildProgress.finish(showTiming: true);

      if (argResults['deploy']) {
        logger.stdout('Deployment has not yet been implemented.');
      }

      logger.stdout('All ${logger.ansi.emphasized('done')}.');
      logger.flush();
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}
