library gen_structs;

import 'package:typegen/coder/structs.dart' as structs_coder;
import 'package:typegen/interpreter/structs.dart' as structs_interpreter;

class StructsGenerator {

  structs_interpreter.StructYaml struct_yaml = new structs_interpreter.StructYaml();
  structs_interpreter.Interpreter interpreter = new structs_interpreter.Interpreter();
  structs_coder.StructClassFileCoder scf_coder = new structs_coder.StructClassFileCoder();
  structs_coder.StructsImportFileCoder sif_coder = new structs_coder.StructsImportFileCoder();

  void generate() {
    var yaml = struct_yaml.readFile();
    var class_defines = interpreter.interpretYaml(yaml);
    scf_coder.coding(class_defines);
    sif_coder.coding(class_defines);
  }
}
