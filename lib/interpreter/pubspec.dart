library interpreter.pubspec;

import 'dart:io';
import 'package:yaml/yaml.dart';

class PubspecYaml{
  String getName(){
    var str = new File("pubspec.yaml").readAsStringSync();
    var yaml = loadYaml(str);
    return yaml["name"];
  }
}