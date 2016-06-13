library coder.structs;

import "dart:io";

import "package:typegen/interpreter/structs.dart" as interpreter
    show StructDefine, Field, StructField;
import "package:typegen/coder/coder.dart";

class StructClassFileCoder {
  void coding(Iterable<interpreter.StructDefine> class_defines) {
    class_defines
        .map(setClassSource)
        .forEach(writeClassSource);
  }

  ClassSource setClassSource(interpreter.StructDefine define) {
    return new ClassSource(define.class_name)
      ..library_define = getLibraryDefine()
      ..class_fields.addAll(getClassFields(define));
  }

  LibraryDefine getLibraryDefine() {
    return new LibraryDefine()
        ..is_library = false
        ..is_part = true
        ..part_of_name = "generated";
  }

  void writeClassSource(ClassSource class_source){
    new Directory("lib/generated/structs").createSync(recursive: true);
    new File("lib/generated/structs/${class_source.class_name}.dart").writeAsStringSync(class_source.toString());
  }

  Iterable<ClassField> getClassFields(interpreter.StructDefine define) {
    var list = <ClassField>[];
    addAll(list, define.string_fields, "String");
    addAll(list, define.string_list_fields, "List<String>");
    addAll(list, define.int_fields, "int");
    addAll(list, define.int_list_fields, "List<int>");
    addAll(list, define.num_fields, "num");
    addAll(list, define.num_list_fields, "List<num>");
    addAll(list, define.date_time_fields, "DateTime");
    addAll(list, define.date_time_list_fields, "List<DateTime>");


    list.addAll(define.struct_fields.map(getStructField));
    list.addAll(define.struct_list_fields.map(getStructListField));
    return list;
  }

  void addAll(List<ClassField> list, List<interpreter.Field> fields,
      String type_name) {
    list.addAll(fields.map((field) => getField(field, type_name)));
  }

  ClassField getField(interpreter.Field field, String type) {
    return new ClassField()
      ..name = field.field_name
      ..type = type;
  }

  ClassField getStructField(interpreter.StructField field) {
    return new ClassField()
      ..name = field.field_name
      ..type = field.type_name;
  }

  ClassField getStructListField(interpreter.StructField field) {
    return new ClassField()
      ..name = field.field_name
      ..type = "List<${field.type_name}>";
  }

}

class StructsIncludeFileCoder {
  void coding(Iterable<interpreter.StructDefine> class_defines) {

    new ClassSource("Structs")

  }
}
