library interpreter.html;

import 'dart:io';
import 'package:html5plus/parser.dart';
import 'package:html5plus/dom.dart';

class Interpreter {

  NodeInfoListCreator node_info_list_creator = new NodeInfoListCreator();

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
    var node_info_list = node_info_list_creator.create(file_name, html);
    var element_info_list = node_info_list
        .where(_isElementInfo)
        .toList();
    return new Template()
      ..face_fields = face_fields_creator.getFaceFields(element_info_list);
  }

  String getDefaultPartName(File file) {
    var file_name = file.uri.pathSegments.last;
    return file_name.substring(0, file_name.length - 5);
  }

  bool _isElementInfo(NodeInfo node_info) =>
      node_info.node is Element;


}

class FaceFieldsCreator {

  String default_data_part;

  /**
   * まずElementParentsのインスタンスにする
   * 各要素がどのDataPartに所属しているかのリストを作る
   * DataPartごとに所属しているElementの一覧を作る
   * DataPartごとにNameAttrを持つ
   */
  List<FaceFields> getFaceFields(List<ElementInfo> element_info_list) {
    // data-part名ごとにグルーピングする
    Map<String, List<ElementInfo>> element_info_list_groups = grouping(
        element_info_list, _groupByMemberOf);

    return element_info_list_groups
        .keys
        .map((data_part) =>
        _createFaceFields(data_part, element_info_list_groups[data_part]))
        .toList();
  }

  String _groupByMemberOf(NodeInfo node_info) =>
      node_info.member_of;

  FaceFields _createFaceFields(String data_part,
      List<ElementInfo> element_info_list) =>
      new FaceFields()
        ..data_part = data_part
        ..face_fields = _getNamedElements(element_info_list);

  List<FaceField> _getNamedElements(List<ElementInfo> element_info_list) =>
      []..addAll(_getNameInputElements(element_info_list))..addAll(
          _getNamedGeneralElement(element_info_list));


  List<FaceField> _getNameInputElements(List<ElementInfo> element_info_list) =>
      element_info_list
          .where(_isNamedElement)
          .where(_isInputElement)
          .map(_createInputFaceField)
          .toList();

  // InputElement以外の要素
  List<FaceField> _getNamedGeneralElement(
      List<ElementInfo> element_info_list) =>
      element_info_list
          .where(_isNamedElement)
          .where(_isGeneralElement)
          .map(_createGeneralFaceField)
          .toList();


  bool _isNamedElement(ElementInfo element_info) =>
      element_info.name != null;


  bool _isInputElement(ElementInfo element_info) =>
      element_info.element.tagName == "input";


  _createInputFaceField(ElementInfo element_info) =>
      new FaceField()
        ..tag = "input"
        ..name = element_info.name
        ..type = element_info.element.attributes["type"];


  bool _isGeneralElement(ElementInfo element_info) =>
      !_isInputElement(element_info);


  FaceField _createGeneralFaceField(ElementInfo element_info) =>
      new FaceField()
        ..tag = element_info.element.tagName
        ..name = element_info.name;


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

class NodeInfoListCreator {

  String default_data_part;
  List<List<Node>> table = [];


  List<NodeInfo> create(String default_data_part, String html) {
    this.default_data_part = default_data_part;
    var dom = parse(html);
    dom.nodes
        .forEach((Node node) => recursive([], node));

    // 使い勝手がいいようにElementParentsでラッピングする
    var node_info_list = _getNodeInfoList();
    ElementInfo first_element = node_info_list.first;
    Iterable<ElementInfo> element_info_list = node_info_list
        .where(_isElementNode);

    // data-partを読み込み
    element_info_list
        .where(_hasDataPartElementInfo)
        .forEach(_setDataPart);

    // もし最上位の要素がdata-partを持っていなかったらファイル名を設定
    if (first_element.data_part == null) {
      first_element.data_part = default_data_part;
    }

    /**
     * member_ofは、最上位要素の場合はnull
     * それ以外で親一覧の中にdata-partを持つ要素がある場合は直近のdata-part
     * 親一覧の中にdata-partを持つ要素がない場合はファイル名
     */

    first_element.member_of = null;

    node_info_list
        .getRange(1, node_info_list.length)
        .where(_hasParentDataPart)
        .forEach(_setMemberOf);

    // parentsの中にdata-partを持つ要素がある場合は
    // そのdata-partの所属とする
    node_info_list
        .where(_hasNotParentDataPart)
        .forEach(_setDefaultMemberOf);


    // 要素が名前を持っているならその名前を使う
    element_info_list
        .where(_hasName)
        .forEach(_setName);

    // 最上位要素が名前を持っていないならデフォルトの名前
    if (first_element.name == null) {
      first_element.name = "element";
    }

    return node_info_list;
  }

  void recursive(List<Element> parents, Node node) {
    if (node is Element || node is Text) {
      parents = parents.toList()
        ..add(node);
      table.add(parents);
      if (node is Element) {
        node.nodes.forEach((node) => recursive(parents, node));
      }
    }
  }

  List<NodeInfo> _getNodeInfoList() =>
      table
          .map(_createNodeInfo)
          .toList();

  NodeInfo _createNodeInfo(List<Node> elements) =>
      elements.last is Element ?
      _createElementInfo(elements) :
      _createTextInfo(elements);

  ElementInfo _createElementInfo(List<Node> elements) =>
      new ElementInfo()
        ..parents = elements.getRange(0, elements.length - 1).toList()
        ..node = elements.last;

  TextInfo _createTextInfo(List<Node> elements) =>
      new TextInfo()
        ..parents = elements.getRange(0, elements.length - 1).toList()
        ..node = elements.last;

  bool _isElementNode(NodeInfo node_info) =>
      node_info is ElementInfo;

  bool _hasDataPartElementInfo(ElementInfo element_info) =>
      _hasDataPart(element_info.element);

  _setDataPart(ElementInfo element_info) =>
      element_info
          .data_part = element_info.element.attributes["data-part"];


  bool _hasParentDataPart(NodeInfo node_info) =>
      node_info
          .parents
          .any(_hasDataPart);

  bool _hasDataPart(Element element) =>
      element.attributes.containsKey("data-part");

  _setMemberOf(NodeInfo node_info) =>
      node_info
          .parents
          .lastWhere(_hasDataPart)
          .attributes["data-part"];

  bool _hasNotParentDataPart(NodeInfo node_info) =>
      !_hasParentDataPart(node_info);

  _setDefaultMemberOf(NodeInfo node_info) =>
      node_info.member_of = default_data_part;


  bool _hasName(ElementInfo element_info) =>
      element_info.element.attributes.containsKey("name");

  _setName(ElementInfo element_info) =>
      element_info.name = element_info.element.attributes["name"];

}

abstract class NodeInfo {
  /**
   * 自分を含まない
   */
  List<Element> parents;

  /**
   * 自分
   */
  Node node;


  /**
   * 所属しているのDataPart
   */
  String member_of;

  String data_part;

  String name;


}

class ElementInfo extends NodeInfo {

  Element get element => node;

  String toString() =>
      "\ntag:${element.tagName}\n name:$name\n member_of:$member_of\n";
}

class TextInfo extends NodeInfo {
  String get text => (node as Text).text;

  String toString() => "\n$text";

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