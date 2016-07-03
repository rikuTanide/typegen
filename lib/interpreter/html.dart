library interpreter.html;

import 'dart:io';
import 'package:html5plus/parser.dart';
import 'package:html5plus/dom.dart';

class Interpreter {

  ElementParentsListCreator element_parents_list_creator = new ElementParentsListCreator();

  FaceFieldsCreator face_fields_creator = new FaceFieldsCreator();


  Iterable<Template> interpretHTMLFiles() {
    return getTemplateFiles().map(interpretHTMLFile);
  }

  Iterable<File> getTemplateFiles() {
    return new Directory("tools/generate")
        .listSync()
        .where((file) => file is File && file.path.endsWith(".html"))
        .map((File file) => file);
  }

  Template interpretHTMLFile(File file) {
    var file_name = getDefaultPartName(file);
    var html = file.readAsStringSync();
    var element_parents_list = element_parents_list_creator.create(file_name, html);
    print(element_parents_list);
    return new Template()
      ..face_fields = face_fields_creator.getFaceFields(element_parents_list);
  }

  String getDefaultPartName(File file) {
    var file_name = file.uri.pathSegments.last;
    return file_name.substring(0, file_name.length - 5);
  }


}

class FaceFieldsCreator {

  String default_data_part;

  /**
   * まずElementParentsのインスタンスにする
   * 各要素がどのDataPartに所属しているかのリストを作る
   * DataPartごとに所属しているElementの一覧を作る
   * DataPartごとにNameAttrを持つ
   */
  List<FaceFields> getFaceFields(List<ElementParents> element_parents_list) {
    // data-part名ごとにグルーピングする
    Map<String, List<ElementParents>> element_parents_groups = grouping(
        element_parents_list, _groupByMemberOf);

    return element_parents_groups
        .keys
        .map((data_part) =>
        _createFaceFields(data_part, element_parents_groups[data_part]))
        .toList();
  }

  String _groupByMemberOf(ElementParents element_parents) =>
      element_parents.member_of;

  FaceFields _createFaceFields(String data_part,
      List<ElementParents> element_parents_list) =>
      new FaceFields()
        ..data_part = data_part
        ..face_fields = _getNamedElements(element_parents_list);

  List<FaceField> _getNamedElements(
      List<ElementParents> element_parents_list) =>
      []..addAll(_getNameInputElements(element_parents_list))..addAll(
          _getNamedGeneralElement(element_parents_list));


  List<FaceField> _getNameInputElements(
      List<ElementParents> element_parents_list) =>
      element_parents_list
          .where(_isNamedElement)
          .where(_isInputElement)
          .map(_createInputFaceField)
          .toList();

  // InputElement以外の要素
  List<FaceField> _getNamedGeneralElement(
      List<ElementParents> element_parents_list) =>
      element_parents_list
          .where(_isNamedElement)
          .where(_isGeneralElement)
          .map(_createGeneralFaceField)
          .toList();


  bool _isNamedElement(ElementParents element_parents) =>
      element_parents.name != null;


  bool _isInputElement(ElementParents element_parents) =>
      element_parents.element.tagName == "input";


  _createInputFaceField(ElementParents element_parents) =>
      new FaceField()
        ..tag = "input"
        ..name = element_parents.name
        ..type = element_parents.element.attributes["type"];


  bool _isGeneralElement(ElementParents element_parents) =>
      !_isInputElement(element_parents);


  FaceField _createGeneralFaceField(ElementParents element_parents) =>
      new FaceField()
        ..type = element_parents.element.tagName
        ..name = element_parents.name;


}

Map<dynamic, List> grouping(List list, dynamic f(dynamic e)) {
  var map = {};
  list.fold(map, (Map map, e) {
    var key = f(e);
    if (!map.containsKey(key)) {
      map[key] = [];
    }
    return map;
  });

  list.fold(map, (Map map, e) {
    var key = f(e);
    map[key].add(e);
    return map;
  });
  return map;
}

List flatten(List l1, List l2) {
  return l1..addAll(l2);
}

List distinct(List l1, l2) {
  if (!l1.contains(l2)) {
    l1.add(l2);
  }
  return l1;
}

class ElementParentsListCreator {

  String default_data_part;
  List<List<Element>> table = [];


  List<ElementParents> create(String default_data_part, String html) {

    this.default_data_part = default_data_part;
    var dom = parse(html);
    dom.nodes
        .forEach((Node node) => recursive([], node));

    // 使い勝手がいいようにElementParentsでラッピングする
    var element_parents_list = _getElementParentsList();

    // data-partを読み込み
    element_parents_list
        .where(_hasElementDataPart)
        .forEach(_setDataPart);

    // もし最上位の要素がdata-partを持っていなかったらファイル名を設定
    if(element_parents_list[0].data_part == null){
      element_parents_list[0].data_part = default_data_part;
    }

    /**
     * member_ofは、最上位要素の場合はnull
     * それ以外で親一覧の中にdata-partを持つ要素がある場合は直近のdata-part
     * 親一覧の中にdata-partを持つ要素がない場合はファイル名
     */

    element_parents_list[0].member_of = null;

    element_parents_list
        .getRange(1,element_parents_list.length)
        .where(_hasParentDataPart)
        .forEach(_setMemberOf);

    // parentsの中にdata-partを持つ要素がある場合は
    // そのdata-partの所属とする
    element_parents_list
        .where(_hasNotParentDataPart)
        .forEach(_setDefaultMemberOf);


    // 要素が名前を持っているならその名前を使う
    element_parents_list
        .where(_hasName)
        .forEach(_setName);

    // 最上位要素が名前を持っていないならデフォルトの名前
    if(element_parents_list[0].name == null){
      element_parents_list[0].name = "element";
    }

    return element_parents_list;
  }

  void recursive(List<Element> parents, Node node) {
    if (node is Element || node is Text) {

      parents = parents.toList()
        ..add(node);
      table.add(parents);
      if (node is Element) {
        node.children.forEach((node) => recursive(parents, node));
      }
    }
  }

  List<ElementParents> _getElementParentsList() =>
      table
          .map(_createElementParents)
          .toList();

  ElementParents _createElementParents(List<Element> elements) =>
      new ElementParents()
        ..parents = elements
        ..element = elements.last;

  bool _hasElementDataPart(ElementParents element_parents) =>
      _hasDataPart(element_parents.element);

  _setDataPart(ElementParents element_parents) =>
      element_parents
          .data_part = element_parents.element.attributes["data-part"];

  Iterable<Element> _getParents(ElementParents element_parents) =>
      element_parents
          .parents
          .getRange(0,element_parents.parents.length - 1);

  bool _hasParentDataPart(ElementParents element_parents) =>
      _getParents(element_parents)
      .any(_hasDataPart);

  bool _hasDataPart(Element element) =>
      element.attributes.containsKey("data-part");

  _setMemberOf(ElementParents element_parents) =>
      _getParents(element_parents)
      .firstWhere(_hasDataPart)
      .attributes["data-part"];

  bool _hasNotParentDataPart(ElementParents element_parents) =>
      !_hasParentDataPart(element_parents);

  _setDefaultMemberOf(ElementParents element_parents) =>
      element_parents.member_of = default_data_part;


  bool _hasName(ElementParents element_parents) =>
      element_parents.element.attributes.containsKey("name");

  _setName(ElementParents element) =>
      element.name = element.element.attributes["name"];

}

class ElementParents {
  /**
   * 自分を含む
   */
  List<Element> parents;

  /**
   * 自分
   */
  Element element;

  /**
   * 所属しているのDataPart
   */
  String member_of;

  String data_part;

  String name;

  toString() => "\ntag:${element.tagName}\n name:$name\n member_of:$member_of\n";

}


class Template {
  List<FaceFields> face_fields;

  toString() {
    return face_fields.map((face_field) => face_field.toString()).toString();
  }

}

class FaceFields {
  String data_part;
  List<FaceField> face_fields;

  toString() {
    return face_fields.map((face_field) => face_field.tag + " " +
        face_field.name + "\n").toString();
  }

}

class FaceField {
  String name;
  String tag;
  String type;
}