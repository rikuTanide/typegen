library gen_structs;

import 'package:typegen/interpreter/pubspec.dart';
import 'package:typegen/coder/structs.dart' as structs_coder;
import 'package:typegen/interpreter/structs.dart' as structs_interpreter;
import 'package:typegen/coder/encoders.dart' as encoders_coder;
import 'package:typegen/coder/decoders.dart' as decoders_coder;

class StructsGenerator {

  PubspecYaml pubspec_yaml = new PubspecYaml();
  structs_interpreter.StructYaml struct_yaml = new structs_interpreter
      .StructYaml();
  structs_interpreter.Interpreter interpreter = new structs_interpreter
      .Interpreter();
  structs_coder.StructClassFileCoder scf_coder = new structs_coder
      .StructClassFileCoder();
  structs_coder.StructsImportFileCoder sif_coder = new structs_coder
      .StructsImportFileCoder();
  encoders_coder.EncodersClassFileCoder ecf_coder = new encoders_coder
      .EncodersClassFileCoder();
  encoders_coder.EncodersImportFileCoder eif_coder = new encoders_coder
      .EncodersImportFileCoder();
  decoders_coder.DecodersClassFileCoder dcf_coder = new decoders_coder
      .DecodersClassFileCoder();
  decoders_coder.DecodersImportFileCoder dif_coder = new decoders_coder
      .DecodersImportFileCoder();


  void generate() {
    var lib_name = pubspec_yaml.getName();
    var yaml = struct_yaml.readFile();
    var class_defines = interpreter.interpretYaml(yaml);
    scf_coder.coding(class_defines);
    sif_coder.coding(class_defines);
    ecf_coder.coding(class_defines);
    eif_coder.coding(class_defines, lib_name);
    dcf_coder.coding(class_defines);
    dif_coder.coding(class_defines, lib_name);
  }
}
