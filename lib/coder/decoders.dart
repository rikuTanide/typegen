library typegen.coder.decoders;

import 'dart:io';
import 'package:typegen/interpreter/structs.dart' as interpreter
    show StructDefine, Field, StructField;
import 'package:typegen/coder/coder.dart';

class DecodersClassFileCoder {
  void coding(Iterable<interpreter.StructDefine> struct_defines) {
    struct_defines
        .map(createClassSource)
        .forEach(writeClassSource);
  }

  ClassSource createClassSource(interpreter.StructDefine define) {
    var class_name = "${define.class_name}Decoder";
    return new ClassSource(class_name)
      ..constructor = createConstructor(class_name)
      ..class_fields = [getStructField(define.class_name)]
      ..getters = createGetters(define)
      ..class_methods = [getTopStruct(define)];
  }

  getTopStruct(interpreter.StructDefine define) {
    var body = ["return new structs.${define.class_name}()"];
    body.addAll(getAssignment(define.int_fields));
    body.addAll(getAssignment(define.int_list_fields));
    body.addAll(getAssignment(define.num_fields));
    body.addAll(getAssignment(define.num_list_fields));
    body.addAll(getAssignment(define.string_fields));
    body.addAll(getAssignment(define.string_list_fields));
    body.addAll(getAssignment(define.date_time_fields));
    body.addAll(getAssignment(define.date_time_list_fields));
    body.addAll(getStructAssignment(define.struct_fields));
    body.addAll(getStructAssignment(define.struct_list_fields));
    body.add(";");

    return new ClassMethod("toStruct")
      ..result_type = "structs." + define.class_name
      ..body = body;
  }

  Iterable<String> getStructAssignment(List<interpreter.StructField> fields) {
    return fields.map((field) {
      var name = field.field_name;
      return "..$name = $name";
    });
  }

  Iterable<String> getAssignment(List<interpreter.Field> fields) {
    return fields.map((field) {
      var name = field.field_name;
      return "..$name = $name";
    });
  }

  List<Getter> createGetters(interpreter.StructDefine define) {
    var results = [];
    results.addAll(getReturnGetters("int", define.int_fields));
    results.addAll(getReturnGetters("List<int>", define.int_list_fields));
    results.addAll(getReturnGetters("num", define.num_fields));
    results.addAll(getReturnGetters("List<num>", define.num_list_fields));
    results.addAll(getReturnGetters("String", define.string_fields));
    results.addAll(getReturnGetters("List<String>", define.string_list_fields));
    results.addAll(getDateTimeGetters(define.date_time_fields));
    results.addAll(getDateTimeListGetters(define.date_time_list_fields));
    results.addAll(getStructGetters(define.struct_fields));
    results.addAll(getStructListGetters(define.struct_list_fields));
    return results;
  }

  Iterable<Getter> getStructListGetters(
      List<interpreter.StructField> struct_list_fields) {
    return struct_list_fields.map((field) {
      var type = "structs." + field.type_name;
      var decoder = field.type_name + "Decoder";
      var field_name = field.field_name;
      return new Getter()
        ..type = type
        ..name = field_name
        ..method = "map[\"$field_name\"]"
            ".map((value) => new $decoder(value).toStruct()).toList()";
    });
  }

  Iterable<Getter> getStructGetters(
      List<interpreter.StructField> struct_fields) {
    return struct_fields.map((field) {
      var type = "structs." + field.type_name;
      var decoder = type + "Decoder";
      var field_name = field.field_name;
      return new Getter()
        ..type = type
        ..name = field_name
        ..method = "new $decoder(map[\"$field_name\"]).toStruct()";
    });
  }

  Iterable<Getter> getDateTimeListGetters(
      List<interpreter.Field> date_time_list_fields) {
    return date_time_list_fields.map((field) {
      var name = field.field_name;
      return new Getter()
        ..type = "List<DateTime>"
        ..name = name
        ..method = "map[\"$name\"].map(DateTime.parse).toList()";
    });
  }

  Iterable<Getter> getDateTimeGetters(
      List<interpreter.Field> date_time_fields) {
    return date_time_fields.map((field) {
      var name = field.field_name;
      return new Getter()
        ..type = "DateTime"
        ..name = field.field_name
        ..method = "DateTime.parse(map[\"$name\"])";
    });
  }

  Iterable<Getter> getReturnGetters(String type,
      List<interpreter.Field> fields) {
    return fields.map((field) {
      var name = field.field_name;
      return new Getter()
        ..type = type
        ..name = name
        ..method = "map[\"$name\"]";
    });
  }

  getStructField(String class_name) {
    return new ClassField()
      ..type = "Map"
      ..name = "map";
  }

  Constructor createConstructor(String class_name) {
    return new Constructor(class_name)
      ..assignment = ["struct"];
  }

  void writeClassSource(ClassSource class_source) {
    var source_file = new SourceFile()
      ..library_define = getLibraryDefine()
      ..class_source_list = [ class_source ];
    new Directory("lib/generated/decoders").createSync(recursive: true);
    new File("lib/generated/decoders/" + class_source.class_name + ".dart")
        .writeAsStringSync(source_file.toString());
  }

  LibraryDefine getLibraryDefine() {
    return new LibraryDefine()
      ..is_library = false
      ..is_part = true
      ..part_of_name = "generated.decoders";
  }
}

class DecodersImportFileCoder {
  void coding(Iterable<interpreter.StructDefine> class_defines,String lib_name) {
    var source_file = new SourceFile()
        ..library_define = getLibDefine(class_defines,lib_name);

    writeSourceFile(source_file);
  }

  LibraryDefine getLibDefine(Iterable<interpreter.StructDefine> class_defines, String lib_name) {
    return new LibraryDefine()
        ..is_library = true
        ..is_part
        ..library_name = "generated.decoders"
        ..imports_alias = {"package:$lib_name/generated/structs.dart" : "structs"}
        ..part_files = getPartFiles(class_defines);
  }

  List<String> getPartFiles(Iterable<interpreter.StructDefine> class_defines) {
    return class_defines
        .map((struct_define) => "decoders/" +  struct_define.class_name + "Decoder.dart")
        .toList();
  }

  void writeSourceFile(SourceFile source_file) {
    new Directory("lib/generated").createSync(recursive: true);
    new File("lib/generated/decoders.dart").writeAsStringSync(source_file.toString());
  }
}