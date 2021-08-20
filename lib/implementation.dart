import 'dart:io';
import 'dart:math';

import 'package:dart_obfuscator/log_level.dart';
import 'package:dart_obfuscator/main.dart';
import 'package:dart_obfuscator/models.dart';

//region Files processing
Structure determineStructure(Directory libDir, String sourceDirPath) {
  if (!libDir.existsSync()) {
    throw "Directory $sourceDirPath does not exists or does not contain /lib dir";
  }

  final rawFiles = libDir.listSync(recursive: false).where((element) => element is File).whereType<File>().toList();

  if (logLevel == LogLevel.VERBOSE) print("Files to obfuscate");
  List<File> filesToObfuscate = findFilesToObfuscate(libDir, rawFiles);
  filesToObfuscate.forEach((element) {
    if (logLevel == LogLevel.VERBOSE) print("${element.path}");
  });
  return Structure(rawFiles, filesToObfuscate);
}

List<File> findFilesToObfuscate(Directory libDir, List<FileSystemEntity> rawFiles) => libDir
    .listSync(recursive: true)
    .whereType<File>()
    .where((element) => element.path.split(".").last == "dart")
    .toList();

/// Returns all sources from all files that have to be obfuscated as string
String scrapCodeToObfuscate(List<File> filesToObfuscate, Directory libDir) {
  final allImports = Set<String>();
  final nonImportLines = <String>[];

  filesToObfuscate.forEach((theFile) {
    theFile.readAsLinesSync().forEach((line) {
      if (isLineImport(line)) {
        allImports.add(line);
      } else if (!isLinePart(line) && !isLineComment(line)) {
        nonImportLines.add(line);
      }
    });
  });

  final allLines = (allImports.toList() + nonImportLines).reduce((value, element) => value + "$element\n");
  return allLines;
}

//endregion

//region imports

bool isLineComment(String line) => line.startsWith("//");

bool isLinePart(String line) => line.startsWith("part ");

bool isLineImport(String line) => line.startsWith('import ');

//endregion

//region Obfuscation

List<String> generateMappingsList() {
  final mappingSymbols = <String>[];
  final alphabet = <String>[];
  var letterCode = 'A'.codeUnitAt(0);
  for (var i = 0; i < (26 * 2); i++) {
    if (i == 26) {
      letterCode += 6; //skip symbols in between Upper case letters and lower case letters
    }
    alphabet.add(String.fromCharCode(letterCode++));
  }

  alphabet.forEach((letterOne) {
    alphabet.forEach((letterTwo) {
      alphabet.forEach((letterThree) {
        mappingSymbols.add("$letterOne$letterTwo$letterThree");
      });
    });
  });

  return mappingSymbols;
}

String renameClasses(String codeToObfuscate, List<String> mappingSymbols, Map<String, String> resultingMapping) {
  final classNames =
      RegExp("class (.*?)[^a-zA-Z0-9_]").allMatches(codeToObfuscate).map((match) => match.group(1)).toList();

  var updatedCode = codeToObfuscate;
  classNames.forEach((theClass) {
    final theMapping = mappingSymbols.removeAt(Random().nextInt(mappingSymbols.length));
    updatedCode = updatedCode.replaceAll(RegExp(theClass), theMapping);
    resultingMapping[theClass] = theMapping;
    print("Rename $theClass to $theMapping");
  });

  return updatedCode;
}

void updateRawFilesWithObfuscatedClasses(List<File> rawFiles, Map<String, String> resultingMapping) {
  findFilesToObfuscate(libDir, rawFiles).forEach((theFile) {
    resultingMapping.forEach((String theClass, String theMapping) {
      final lines = theFile.readAsLinesSync();
      final newLines = <String>[];

      for (final line in lines) {
        if (!isLineComment(line) || !isLinePart(line) || !isLineImport(line)) {
          final updatedLineText = line.replaceAll(RegExp(theClass), theMapping);
          newLines.add(updatedLineText);
        } else {
          newLines.add(line);
        }
      }

      theFile.writeAsStringSync(newLines.join('\n'));
    });
  });
}

//endregion
