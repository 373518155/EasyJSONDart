

import 'package:sprintf/sprintf.dart';

import 'EasyJSONBase.dart';
import 'EasyJSONException.dart';
import 'EasyJSONObject.dart';
import 'json/JSON.dart';
import 'json/JSONArray.dart';
import 'json/JSONObject.dart';

class EasyJSONArray extends EasyJSONBase implements Iterable<Object> {
    /**
     * EasyJSONArray的内部表示
     */
    JSONArray jsonArray;

    /**
     * 生成一个EasyJSONArray
     * @param args
     * @return
     */
    static EasyJSONArray generate([List args]) {
        args ??= [];

        var easyJSONArray = EasyJSONArray();
        for (var arg in args) {
            easyJSONArray.append(arg);
        }

        return easyJSONArray;
    }

    /**
     * 从JSON字符串构造一个EasyJSONArray
     * @param jsonString
     */
    EasyJSONArray({String jsonString, Iterable iterable}) {
        if (jsonString == null && iterable == null) { // 如果没有指定，则采用String方式
            jsonString = JSON.STR_EMPTY_ARRAY;
        }
        try {
            if (jsonString != null) {
                jsonArray = JSONArray(json: jsonString);
            } else if (iterable != null) {
                jsonArray = JSONArray(iterable: iterable);
            }

            json = jsonArray; // 关联父类的json
        } catch (e) {
        }

        jsonType = EasyJSONBase.JSON_TYPE_ARRAY;
    }


    /**
     * 在EasyJSONArray尾部插入一个值
     * @param value
     * @return
     */
    EasyJSONArray append(Object value) {
        value ??= JSONObject.NULL;

        // 类型转换
        if (value is EasyJSONObject) {
            value = (value as EasyJSONObject).getJSONObject();
        } else if (value is EasyJSONArray) {
            value = (value as EasyJSONArray).getJSONArray();
        }
        jsonArray.put(value);
        return this;
    }

    /**
     * 获取EasyJSONArray内部表示的JSONArray
     * @return
     */
    JSONArray getJSONArray() {
        return jsonArray;
    }

    /**
     * 在EasyJSONArray中设置指定索引的值
     * @param index
     * @param value
     * @return
     * @throws EasyJSONException
     */
    EasyJSONArray set(int index, Object value) {
        if (jsonArray == null || jsonArray.length() <= index) {
            var errMsg = sprintf("Array Index Out Of Bounds, length: %d, index: %d", [jsonArray.length(), index]);
            throw EasyJSONException(errMsg);
        }

        jsonArray.putAt(index, value);

        return this;
    }


    /**
     * 获取当前元素个数
     * @return
     */
    int size() {
        return jsonArray.length();
    }

  @override
  bool any(bool Function(Object element) test) {
    // TODO: implement any
    return null;
  }

  @override
  Iterable<R> cast<R>() {
    // TODO: implement cast
    return null;
  }

  @override
  bool contains(Object element) {
    // TODO: implement contains
    return null;
  }

  @override
  Object elementAt(int index) {
    // TODO: implement elementAt
    return null;
  }

  @override
  bool every(bool Function(Object element) test) {
    // TODO: implement every
    return null;
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(Object element) f) {
    // TODO: implement expand
    return null;
  }

  @override
  // TODO: implement first
  Object get first => null;

  @override
  Object firstWhere(bool Function(Object element) test, {Object Function() orElse}) {
    // TODO: implement firstWhere
    return null;
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, Object element) combine) {
    // TODO: implement fold
    return null;
  }

  @override
  Iterable<Object> followedBy(Iterable<Object> other) {
    // TODO: implement followedBy
    return null;
  }

  @override
  void forEach(void Function(Object element) f) {
    // TODO: implement forEach
    if (jsonArray != null) {
      var len = jsonArray.length();
      for (var i = 0; i < len; i++) {
        var elem = jsonArray.get(i);
        if (elem is JSONObject) {
          f(EasyJSONObject(map: elem.getHashMap()));
        } else if (elem is JSONArray) {
          f(EasyJSONArray(iterable: elem.getList()));
        } else {
          f(elem);
        }
      }
    }
  }

  @override
  // TODO: implement isEmpty
  bool get isEmpty => null;

  @override
  // TODO: implement isNotEmpty
  bool get isNotEmpty => null;

  @override
  // TODO: implement iterator
  Iterator<Object> get iterator => null;

  @override
  String join([String separator = ""]) {
    // TODO: implement join
    return null;
  }

  @override
  // TODO: implement last
  Object get last => null;

  @override
  Object lastWhere(bool Function(Object element) test, {Object Function() orElse}) {
    // TODO: implement lastWhere
    return null;
  }

  @override
  // TODO: implement length
  int get length => null;

  @override
  Iterable<T> map<T>(T Function(Object e) f) {
    // TODO: implement map
    return null;
  }

  @override
  Object reduce(Object Function(Object value, Object element) combine) {
    // TODO: implement reduce
    return null;
  }

  @override
  // TODO: implement single
  Object get single => null;

  @override
  Object singleWhere(bool Function(Object element) test, {Object Function() orElse}) {
    // TODO: implement singleWhere
    return null;
  }

  @override
  Iterable<Object> skip(int count) {
    // TODO: implement skip
    return null;
  }

  @override
  Iterable<Object> skipWhile(bool Function(Object value) test) {
    // TODO: implement skipWhile
    return null;
  }

  @override
  Iterable<Object> take(int count) {
    // TODO: implement take
    return null;
  }

  @override
  Iterable<Object> takeWhile(bool Function(Object value) test) {
    // TODO: implement takeWhile
    return null;
  }

  @override
  List<Object> toList({bool growable = true}) {
    // TODO: implement toList
    return null;
  }

  @override
  Set<Object> toSet() {
    // TODO: implement toSet
    return null;
  }

  @override
  Iterable<Object> where(bool Function(Object element) test) {
    // TODO: implement where
    return null;
  }

  @override
  Iterable<T> whereType<T>() {
    // TODO: implement whereType
    return null;
  }
}
