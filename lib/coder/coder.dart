library coder.coder;

class ClassSource {

  String class_name;

  ClassSource(this.class_name);

  List<ClassField> class_fields = [];

  Constructor constructor = new Constructor();

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

class ClassMethod {
  List<String> lines(){
    return [];
  }
}

class Setter {
}

class Getter {
}

class Constructor {
  List<String> lines(){
    return [];
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

  List<String> lines() {
    if (is_library) {
      return ["library $library_name;"]
        ..addAll(imports.map((i) => "import \"$i\";"))
        ..addAll(part_files.map((p) => "part \"$p\";"));
    }

    if (is_part) {
      return ["part of $part_of_name;"];
    }
    return [];
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