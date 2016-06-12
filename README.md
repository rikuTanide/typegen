# typegen
Dartの型自動生成ツール

## 機能
 1. YAMLからクラスを生成
 1. 1とJSONのエンコーダーを生成
 1. HTMLからクラスを生成
 1. 1で生成したクラスと3で生成したクラスのバインダーを生成

### 詳細

#### YAMLからクラスを生成

``` structs.yaml
Animal:
  name: String
  age: int

```

↓自動生成

``` Animal.dart
class Animal {
  String name;
  int age;
}
```

#### 1とJSONのエンコーダー

```
import [struct] as structs;

class Animal {

  structs.Animal struct;

  Animal(this.struct);

  String get name => struct.name;

  int get age => struct.age;

  Map toMap() {
    return {
      "name" : name,
      "age" : age,
    };
  }

}
```

```

import [struct] as structs;

class Animal {

  Map map;

  Animal(this.map);

  String get name => map["name"];

  int age => map["age"];

  structs.Animal toStruct(){
    return new structs.Animal()
      ..name = name
      ..ane = age;
  }

}
```

#### HTMLからクラスを生成

``` Animal.html

<!doctype html>
<html data-struct="Animal">
<body>
<form>
  <input type="text" name="name" />
  <input type="number" name="age" />
</form>
</body>
</html>

```

↓自動生成

``` Animal.dart

class Animal {

  TextInputElement name;

  NumberInputElement age;

  Animal(){
    name = document.getElementsByName("name").first;
    age = document.getElementsByName("age").first;
  }

}
```

#### 1と3のバインダー

```
import [face] as faces;
import [struct] as structs;

class Animal {

  faces.Animal face;

  String get name => face.name.value;

  int get age => face.age.valueAsNumber.floor;

  structs.Animal toStruct() {
    return new structs.Animal()
      ..name = name
      ..age = age;
  }

}