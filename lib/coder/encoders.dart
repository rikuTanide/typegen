library coder.encoders;
import 'dart:io';
import "package:typegen/interpreter/structs.dart" as interpreter
    show StructDefine, Field, StructField;
import "package:typegen/coder/coder.dart";

class EncodersClassFileCoder {

  void coding(Iterable<interpreter.StructDefine> struct_defines) {
    struct_defines
        .map(createClassSource)
        .forEach(writeClassSource);
  }

  ClassSource createClassSource(interpreter.StructDefine define) {
    var class_name = "${define.class_name}Encoder";
    return new ClassSource(class_name)
      ..constructor = createConstructor(class_name)
      ..class_fields = [getStructField(define.class_name)]
      ..getters = createGetters(define)
      ..class_methods = [getToMap(define)];
  }

  ClassMethod getToMap(interpreter.StructDefine define) {
    var body = ["return {"];
    body.addAll(getPair(define.int_fields));
    body.addAll(getPair(define.int_list_fields));
    body.addAll(getPair(define.num_fields));
    body.addAll(getPair(define.num_list_fields));
    body.addAll(getPair(define.string_fields));
    body.addAll(getPair(define.string_list_fields));
    body.addAll(getPair(define.date_time_fields));
    body.addAll(getPair(define.date_time_list_fields));
    body.addAll(getStructPair(define.struct_fields));
    body.addAll(getStructPair(define.struct_list_fields));
    body.add("};");
    return new ClassMethod("toMap")
      ..result_type = "Map"
      ..body = body;
  }

  Iterable<String> getPair(List<interpreter.Field> fields) {
    return fields.map((field) => "\"${field.field_name}\" : ${field.field_name},");
  }
  Iterable<String> getStructPair(List<interpreter.StructField> fields) {
    return fields.map((field) => "\"${field.field_name}\" : ${field.field_name},");
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

  Iterable<Getter> getStructGetters(
      List<interpreter.StructField> struct_fields) {
    return struct_fields.map((field) {
      var type = field.type_name;
      var encoder = type + "Encoder";
      return new Getter()
        ..type = "Map"
        ..name = field.field_name
        ..method = "new $encoder(struct.${field.field_name}).toMap()";
    });
  }

  Iterable<Getter> getStructListGetters(
      List<interpreter.StructField> struct_fields) {
    return struct_fields.map((field) {
      var type = field.type_name;
      var encoder = "${type}Encoder";
      return new Getter()
        ..type = "List<Map>"
        ..name = field.field_name
        ..method = "struct.${field
            .field_name}.map((value) => new $encoder(value).toMap()).toList()";
    });
  }

  Iterable<Getter> getDateTimeListGetters(
      List<interpreter.Field> date_time_list_fields) {
    return date_time_list_fields.map((field) {
      return new Getter()
        ..type = "List<String>"
        ..name = field.field_name
        ..method = "struct.${field
            .field_name}.map((dt) => dt.toString()).toList()";
    });
  }

  Iterable<Getter> getDateTimeGetters(
      List<interpreter.Field> date_time_fields) {
    return date_time_fields.map((date_time_field) {
      return new Getter()
        ..type = "String"
        ..name = date_time_field.field_name
        ..method = "struct.${date_time_field.field_name}.toString()";
    });
  }

  Iterable<Getter> getReturnGetters(String type,
      List<interpreter.Field> fields) {
    return fields.map((field) {
      return new Getter()
        ..type = type
        ..name = field.field_name
        ..method = "struct.${field.field_name}";
    });
  }


  ClassField getStructField(String define_type) {
    return new ClassField()
      ..type = "structs." + define_type
      ..name = "struct";
  }

  Constructor createConstructor(String class_name) {
    return new Constructor(class_name)
      ..assignment = ["struct"];
  }

  void writeClassSource(ClassSource class_source) {
    var source_file = new SourceFile()
        ..library_define = getLibraryDefine()
        ..class_source_list = [ class_source ];
    new Directory("lib/generated/encoders").createSync(recursive: true);
    new File("lib/generated/encoders/" + class_source.class_name + ".dart")
        .writeAsStringSync(source_file.toString());
  }

  LibraryDefine getLibraryDefine() {
    return new LibraryDefine()
      ..is_library = false
      ..is_part = true
      ..part_of_name = "generated.encoders";
  }
}

class EncodersImportFileCoder {

  void coding(Iterable<interpreter.StructDefine> class_defines){
    var source_file = new SourceFile()
        ..library_define = getLibDefine(class_defines);

    writeSorceFile(source_file);
  }

  void writeSorceFile(SourceFile source_file) {
    new Directory("lib/generated").createSync(recursive: true);
    new File("lib/generated/encoders.dart").writeAsStringSync(source_file.toString());
  }

  LibraryDefine getLibDefine(Iterable<interpreter.StructDefine> class_defines) {
    return new LibraryDefine()
      ..is_library = true
      ..is_part = false
      ..library_name = "generated.encoders"
      ..imports_alias = {"package:typegen/generated/structs.dart" : "structs"}
      ..part_files = getPartFiles(class_defines);
  }

  List<String> getPartFiles(Iterable<interpreter.StructDefine> class_defines) {
    return class_defines
        .map((struct_define) => "encoders/" +  struct_define.class_name + "Encoder.dart")
        .toList();
  }
}
