#!/usr/bin/env dart
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:tota/cli.dart';

void main(List<String> args) {
  CommandRunner(title, description)
    ..addCommand(InitCommand())
    ..addCommand(NewCommand())
    ..addCommand(BuildCommand())
    ..run(args).catchError((error) {
      print(error);
      exit(64); // Exit code 64 indicates a usage error.
    });
}
