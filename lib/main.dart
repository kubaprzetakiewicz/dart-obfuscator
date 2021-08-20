import 'dart:io';

import 'package:dart_obfuscator/implementation.dart';
import 'package:dart_obfuscator/log_level.dart';

final logLevel = LogLevel.DEBUG;
final obfuscationMap = Map<String, String>();
final packageName = 'REPLACE_ME';
final sourceDirPath = "REPLACE_ME";
final libDir = Directory("$sourceDirPath/lib");

void main(List<String> args) async {
  final programStartTime = DateTime.now().millisecondsSinceEpoch;

  // Preparation
  final structure = determineStructure(libDir, sourceDirPath);

  // Files processing
  final codeToObfuscate = scrapCodeToObfuscate(structure.filesToObfuscate, libDir);

  // Obfuscation
  final resultingMapping = Map<String, String>();
  final mappingSymbols = generateMappingsList();
  renameClasses(codeToObfuscate, mappingSymbols, resultingMapping);
  updateRawFilesWithObfuscatedClasses(structure.rawFiles, resultingMapping);

  print("________________");
  final executionTime = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - programStartTime);
  print("Obfuscation completed in ${executionTime.toIso8601String().split(':').last}");
}
