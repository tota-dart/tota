#!/usr/bin/env dart
import 'package:args/command_runner.dart';
import 'package:tota/cli.dart';

void main(List<String> args) {
  CommandRunner('tota', 'Static site generator.')
    ..addCommand(BuildCommand())
    ..addCommand(NewCommand())
    ..run(args);
}
