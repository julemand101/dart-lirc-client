library ccompile.example.example_build;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:ccompile/ccompile.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as pathos;

void main(List<String> args) async {
  await print(Isolate.resolvePackageUri(Uri.parse("package:dart_lirc_client/lirc_extension.yaml")));
  Program.main(args);
}

class Program {
  static int buildProject(projectPath, Map messages) {
    var workingDirectory = pathos.dirname(projectPath);
    var message = messages['start'];
    if (!message.isEmpty) {
      print(message);
    }

    var logger = new Logger("Builder");
    logger.onRecord.listen((record) {
      try {
        var decoder = new JsonDecoder();
        var message = decoder.convert(record.message);
        if (message is Map) {
          if (message["operation"] == "run") {
            var parameters = message["parameters"];
            if (parameters is Map) {
              var executable = parameters["executable"];
              if (executable is String) {
                var arguments = parameters["arguments"];
                if (arguments is List) {
                  print("$executable ${arguments.join(" ")}");
                }
              }
            }
          }
        }
      } catch (e) {}
    });

    ProjectBuilder.logger = logger;
    var builder = new ProjectBuilder();
    var project = builder.loadProject(projectPath);
    var result = builder.buildAndClean(project, workingDirectory);
    if (result.exitCode == 0) {
      var message = messages['success'];
      if (!message.isEmpty) {
        print(message);
      }
    } else {
      var message = messages['error'];
      if (!message.isEmpty) {
        print(message);
      }
    }

    return result.exitCode == 0 ? 0 : 1;
  }

  static String getRootScriptDirectory() {
    return pathos.dirname(Platform.script.toFilePath());
  }

  static void _checkEnv() {
    var undef =
        const ['DART_SDK'].where((v) => !Platform.environment.containsKey(v));
    if (undef.isNotEmpty) {
      stderr.writeln(
          'Required environment variables are undefined: ${undef.join(", ")}');
      exit(1);
    }
  }

  static void main(List<String> args) {
    _checkEnv();
    var basePath = Directory.current.path;
    var projectPath = toAbsolutePath('lib/lirc_extension.yaml', basePath);
    var result = Program.buildProject(projectPath, {
      'start': 'Building project "$projectPath"',
      'success': 'Building complete successfully',
      'error': 'Building complete with some errors'
    });

    exit(result);
  }

  static String toAbsolutePath(String path, String base) {
    if (pathos.isAbsolute(path)) {
      return path;
    }

    path = pathos.join(base, path);
    return pathos.absolute(path);
  }
}
