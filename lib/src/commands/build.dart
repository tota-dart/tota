import 'dart:io';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import '../../tota.dart' as tota;
import '../config.dart';

class BuildCommand extends Command {
  final name = 'build';
  final description = 'Generate static files.';

  BuildCommand() {
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
    argParser.addFlag('deploy',
        abbr: 'd', negatable: false, help: 'Deploy after build finishes.');
  }

  void run() async {
    dotenv.load();

    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      // Delete existing public directory.
      var publicDir = Directory.fromUri(config.publicDir);
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
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}
