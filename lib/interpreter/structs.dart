library interpreter.structs;

import 'dart:io';
import "package:yaml/yaml.dart";

class StructYaml {
  Map readFile() {
    var str = new File("tools/generate/structs.yaml").readAsStringSync();
    return loadYaml(str);
  }
}


class Interpreter {
  Iterable<StructDefine> interpretYaml(Map yaml) {
    return yaml
        .keys
        .map((class_name) => _getClassDefine(class_name, yaml[class_name]));
  }

  StructDefine _getClassDefine(String class_name,
      Map<String, String> define_map) {
    return new StructDefine(class_name)
      ..string_fields = getFields(define_map, "String")
      ..string_list_fields = getFields(define_map, "String[]")
      ..int_fields = getFields(define_map, "int")
      ..int_list_fields = getFields(define_map, "int[]")
      ..num_fields = getFields(define_map, "num")
      ..num_list_fields = getFields(define_map, "num[]")
      ..date_time_fields = getFields(define_map, "DateTime")
      ..date_time_list_fields = getFields(define_map, "DateTime[]")
      ..struct_fields = getStructFields(define_map)
      ..struct_list_fields = getStructListFields(define_map);
  }

  List getStructListFields(Map<String, String> define_map) {
    return define_map
        .keys
        .where((field_name) => (!isPrimitive(define_map[field_name])) &&
        (define_map[field_name].endsWith("[]")))
        .map((name) => new StructField(
        name, getStructListFieldName(define_map[name]))).toList();
  }

  String getStructListFieldName(String type) {
    return type.substring(0, type.length - 2);
  }

  bool isPrimitive(String field_name) {
    switch (field_name) {
      case "String":
      case "String[]":
      case "int":
      case "int[]":
      case "num":
      case "num[]":
      case "DateTime":
      case "DateTime[]":
        return true;
    }
    return false;
  }

  List getStructFields(Map<String, String> define_map) {
    return define_map
        .keys
        .where((field_name) => (!isPrimitive(define_map[field_name])) &&
        (!define_map[field_name].endsWith("[]")))
        .map((name) => new StructField(name, define_map[name])).toList();
  }

  List<Field> getFields(Map<String, String> define_map, String type_name) {
    return whereTypeEquals(define_map, type_name)
        .map((name) => new Field(name))
        .toList();
  }


  Iterable<String> whereTypeEquals(Map<String, String> define_map,
      String search_type_name) {
    return define_map
        .keys
        .where((field_name) => search_type_name == define_map[field_name]);
  }

}

class Field {
  String field_name;

  Field(this.field_name);
}

class StructField {
  String field_name;
  String type_name;

  StructField(this.field_name, this.type_name);
}

class StructDefine {

  String class_name;

  StructDefine(this.class_name);

  List<Field> string_fields;
  List<Field> string_list_fields;

  List<Field> int_fields;
  List<Field> int_list_fields;

  List<Field> num_fields;
  List<Field> num_list_fields;

  List<Field> date_time_fields;
  List<Field> date_time_list_fields;

  List<StructField> struct_fields;
  List<StructField>struct_list_fields;


}