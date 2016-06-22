library coder.coder;

class ClassSource {

  String class_name;

  ClassSource(this.class_name) : constructor = new DefaultConstructor() ;

  List<ClassField> class_fields = [];

  Constructor constructor;

  List<Getter> getters = [];

  List<Setter> setters = [];

  List<ClassMethod> class_methods = [];


  List<String> lines() {

    var lines = ["class $class_name {"];

    class_fields.forEach(lines.add);

    constructor.lines().forEach(lines.add);

    getters.forEach(lines.add);

    setters.forEach(lines.add);

    class_methods.forEach((method) => method.lines().forEach(lines.add));

    lines.add("}");

    return lines;
  }

}

class DefaultConstructor extends Constructor {

  DefaultConstructor() : super("");

  @override
  List<String> lines() {
    return [];
  }
}

class Argument{
  String type;
  String name;
}

class ClassMethod {

  String result_type = "void";

  String name;

  List<Argument> arguments = [];

  List<String> body;

  ClassMethod(this.name);


  List<String> lines(){
    var arg_str = getArgStr();
    var result = ["$result_type $name ($arg_str){"];
    result.addAll(body);
    result.add("}");
    return result;

  }

  String getArgStr() {
    return arguments
        .map((arg) => arg.type + " " + arg.name)
        .join(",");
  }
}

class Setter {
}

class Getter {
  String type;
  String name;
  /** ;は自動挿入されるのでつけない */
  String method;

  String toString(){
    return "$type get $name => $method;";
  }
}

class Constructor {

  String class_name;

  List<String>assignment;

  Constructor(this.class_name);

  List<String> lines(){
    var assignment_arguments = getAssignmentArguments();
    return [
      "  $class_name ($assignment_arguments);"
    ];
  }

  String getAssignmentArguments() {
    return assignment
        .map((name) => "this.$name")
        .join(",");
  }
}

class ClassField {

  String name;

  String type;

  String toString() => "  $type $name;";

}

class LibraryDefine {
  bool is_library = true;

  String library_name;

  List<String> part_files = [];

  bool is_part = false;

  String part_of_name;

  List<String> imports = [];

  Map<String,String> imports_alias = {};

  List<String> lines() {
    if (is_library) {
      return ["library $library_name;"]
        ..addAll(imports.map((i) => "import \"$i\";"))
        ..addAll(getImportsAlias())
        ..addAll(part_files.map((p) => "part \"$p\";"));
    }

    if (is_part) {
      return ["part of $part_of_name;"];
    }
    return [];
  }

  Iterable<String> getImportsAlias() {
    return imports_alias.keys
        .map((path) => "import \"$path\" as ${imports_alias[path]};");
  }

}

class SourceFile {
  LibraryDefine library_define;

  List<ClassSource> class_source_list = [];

  String toString(){
    var sb = new StringBuffer();

    library_define.lines().forEach(sb.writeln);

    class_source_list.forEach((class_source) => class_source.lines().forEach(sb.writeln));

    return sb.toString();
  }

}