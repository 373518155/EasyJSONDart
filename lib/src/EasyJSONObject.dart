

import 'dart:collection';


import 'EasyJSONArray.dart';
import 'EasyJSONBase.dart';
import 'json/JSON.dart';
import 'json/JSONObject.dart';

class EasyJSONObject extends EasyJSONBase {
    /**
     * EasyJSONObject的内部表示
     */
    JSONObject jsonObject;

    /**
     * 生成一个EasyJSONObject
     * @param args
     * @return
     */
    static EasyJSONObject generate([List args]) {
        args ??= [];
        if (args.length % 2 != 0) {  // 长度必须为2的倍数
            return null;
        }

        var easyJSONObject = EasyJSONObject();

        var counter = 0;
        String name;
        for (var arg in args) {
            if (counter % 2 == 0) {  // name
                if (!(arg is String)) {  // JSON对的键名必须为字符串类型
                    return null;
                }

                name = arg;
            } else { // value
                try {
                    // 添加name/value对
                    easyJSONObject.set(name, arg);
                } catch (e) {
                    return null;
                }
            }
            ++counter;
        }

        return easyJSONObject;
    }




    /**
     * 从JSON字符串构造一个EasyJSONObject
     * @param jsonString
     */
    EasyJSONObject({String jsonString, Map map}) {
        if (jsonString == null && map == null) { // 如果没有指定，则采用String方式
            jsonString = JSON.STR_EMPTY_OBJECT;
        }
        try {
            if (jsonString != null) {
                jsonObject = JSONObject(json: jsonString);
            } else if (map != null) {
                jsonObject = JSONObject(map: map);
            }

            json = jsonObject; // 关联父类的json
        } catch (e) {
        }

        jsonType = EasyJSONBase.JSON_TYPE_OBJECT;
    }


    /**
     * 获取EasyJSONObject内部表示的JSONObject
     * @return
     */
    JSONObject getJSONObject() {
        return jsonObject;
    }

    /**
     * 在EasyJSONObject中设置一个name/value对
     * @param name
     * @param value
     * @return
     * @throws EasyJSONException
     */
    EasyJSONObject set(String name, Object value) {
        value ??= JSONObject.NULL;

        // 类型转换
        if (value is EasyJSONObject) {
            value = (value as EasyJSONObject).getJSONObject();
        } else if (value is EasyJSONArray) {
            value = (value as EasyJSONArray).getJSONArray();
        }

        jsonObject.put(name, value);
        return this;
    }

    /**
     * 判断path是否存在
     * @param path
     * @return
     */
    bool exists(String path) {
        var exists = true;
        try {
            get(path);
        } catch (e) {
            exists = false;
        }

        return exists;
    }


    /**
     * 返回entrySet，可用于遍历JSONObject
     * @return
     */
    Iterable<MapEntry<String, Object>> entrySet() {
        return jsonObject.entrySet();
    }


    HashMap<String, Object> getHashMap() {
        return jsonObject.getHashMap();
    }
}
