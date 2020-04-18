


/*
参考  http://www.json.org/
JSON的两种操作:
1.parse 2.generate


JSON的两种数据结构:
1.对象：无序的，由name/value pairs构成
2.数组：有序的，由各种value构成

value的类型:
1.string
2.number
3.object
4.array
5.true
6.false
7.null

 */





import 'EasyJSONArray.dart';
import 'EasyJSONObject.dart';
import 'json/JSONArray.dart';
import 'json/JSONObject.dart';


class EasyJSONBase {
    static final int JSON_TYPE_INVALID = 0;  // 无效的JSON类型
    static final int JSON_TYPE_OBJECT = 1;
    static final int JSON_TYPE_ARRAY = 2;

    Object json;  // 内部表示的JSON，可能是JSONObject或JSONArray

    int jsonType = JSON_TYPE_INVALID;

    int getJsonType() {
        return jsonType;
    }


    /**
     * 判断给定的字符串是否为JSON格式的字符串(支持JSON对象和数组)
     * @param jsonString
     * @return
     */
    static bool isJSONString(String jsonString) {
        if (jsonString == null || jsonString.length < 1) {
            return false;
        }
        try {
            var jsonType = guessJSONType(jsonString);  // 需要先确定类型
            if (jsonType == JSON_TYPE_OBJECT) {
                var jsonObject = JSONObject(json: jsonString);
            } else if (jsonType == JSON_TYPE_ARRAY) {
                var jsonArray = JSONArray(json: jsonString);
            } else {
                return false;
            }

        } catch (e) {
            // e.printStackTrace();
            return false;
        }
        return true;
    }

    static int guessJSONType(String jsonString) {
        if (jsonString == null) {
            return JSON_TYPE_INVALID;
        }

        var len = jsonString.length;
        for (var i = 0; i < len; ++i) {
            var ch = jsonString[i];
            if (ch == '{') {
                return JSON_TYPE_OBJECT;
            }
            if (ch == '[') {
                return JSON_TYPE_ARRAY;
            }
        }

        return JSON_TYPE_INVALID;
    }


    static EasyJSONBase parse(String jsonString) {
        var jsonType = guessJSONType(jsonString);
        if (jsonType == JSON_TYPE_OBJECT) {
            return EasyJSONObject(jsonString: jsonString);
        } else if (jsonType == JSON_TYPE_ARRAY) {
            return EasyJSONArray(jsonString: jsonString);
        }

        return null;
    }


    /**
     * 将path分割成各个name，例如
     * name1.name2[0][2].name3[1]  分拆成  name1, name2, [0], [2], name[3], [1]
     * [2].name1[1]
     * @param path
     * @return
     */
    static List<String> splitPath(String path) {
        path = path.trim();
        var snippets = path.split("."); // 用点号来分隔不同的层级
        var nameList = List<String>();

        for (var snippet in snippets) {
            // SLog.info("snippet[%s]", snippet);
            var len = snippet.length;
            var i = 0;
            var j = 0;
            String name;
            var beginChar = snippet[0];
            while (true) {
                var ch = snippet[j];

                if (beginChar == '[') {  // 是数组索引
                    if (ch == ']') {
                        ++j;  // 跳到中括号的下一个
                        name = snippet.substring(i, j);
                        nameList.add(name);
                        i = j;
                        if (i >= len) {
                            break;
                        }
                        beginChar = snippet[i];
                    }
                } else {  // 是对象字段
                    if (j + 1 == len) {
                        name = snippet.substring(i, j + 1);
                        nameList.add(name);
                        break;
                    }
                    if (ch == '[') {
                        name = snippet.substring(i, j);
                        nameList.add(name);
                        i = j;

                        if (i >= len) {
                            break;
                        }
                        beginChar = snippet[i];
                    }
                }
                ++j;
            }
        }

        return nameList;
    }


    /*
     * path 路径，可能为int或String类型
     *  如果是int，表示从JSONArray中取值
     *  如果是String, 表示从JSONObject中取值
     */
    Object get(Object path) {
        if (path is int) { // 如果path是整数，表示在Array中获取指定位置的值
            var index = path;
            var jsonArray = json as JSONArray;
            if (jsonArray == null) {
                return null;
            }

            var value = jsonArray.get(index);

            if (value is JSONObject) {
                value = EasyJSONObject(map: (value as JSONObject).nameValuePairs);
            } else if (value is JSONArray) {
                value = EasyJSONArray(iterable: (value as JSONArray).values);
            }
            // SLog.info("valueClass[%s]", value.getClass());

            return value;
        } else if (path is String) {
            var nameList = splitPath(path);

            var value = json;  // 赋初始值，从本层开始
            for (var name in nameList) {
                name = name.trim();
                if (name.startsWith("[")) {  // 以中括号开始，表明是个Array
                    // 去除开始和结束的中括号
                    var indexStr = name.substring(1, name.length - 1);
                    indexStr = indexStr.trim();
                    // SLog.info("indexStr[%s]", indexStr);

                    var index = int.parse(indexStr);  // 得出Array的索引

                    value = (value as JSONArray).get(index);
                } else {  // 否则，表明是个Object
                    value = (value as JSONObject).get(name);
                }
            }

            var valueType = "UNKNOWN";
            if (JSONObject.NULL.equals(value)) {
                valueType = "NULL";
            } else if (value is bool) {
                valueType = "BOOLEAN";
            } else if (value is String) {
                valueType = "STRING";
            } else if (value is double) {
                valueType = "DOUBLE";
            } else if (value is int) {
                valueType = "INTEGER";
            } else if (value is JSONObject) {
                valueType = "OBJECT";
                value = EasyJSONObject(map: (value as JSONObject).nameValuePairs);
            } else if (value is JSONArray) {
                valueType = "ARRAY";
                value = EasyJSONArray(iterable: (value as JSONArray).values);
            }
            // SLog.info("valueType[%s]", valueType);

            return value;
        } else {
            return null;
        }
    }

    bool getBoolean(Object path) {
        return get(path);
    }

    int getInt(Object path) {
        return get(path);
    }

    double getDouble(Object path) {
        return get(path);
    }


    String getString(Object path) {
        return get(path);
    }

    /**
     * 以安全方式获取字符串，如果获取的是null，转换为空字符串""
     * @param path
     * @return
     * @throws EasyJSONException
     */
    String getSafeString(Object path) {
        var result = getString(path);

        result ??= "";
        return result;
    }


    EasyJSONArray getArray(Object path) {
        var result = get(path);
        if (JSONObject.NULL.equals(result)) { // 如果那个字段的值是null，直接返回null
            return null;
        }
        return result as EasyJSONArray;
    }

    /**
     * 以安全方式获取数组，如果获取的是null，转换为空数组[]
     * @param path
     * @return
     * @throws EasyJSONException
     */
    EasyJSONArray getSafeArray(Object path) {
        var result = getArray(path);

        if (result == null || JSONObject.NULL.equals(result)) {
            result = EasyJSONArray.generate();
        }

        return result;
    }


    EasyJSONObject getObject(Object path) {
        var result = get(path);
        if (JSONObject.NULL.equals(result)) { // 如果那个字段的值是null，直接返回null
            return null;
        }
        return result;
    }

    /**
     * 以安全方式获取对象，如果获取的是null，转换为空对象{}
     * @param path
     * @return
     * @throws EasyJSONException
     */
    EasyJSONObject getSafeObject(Object path) {
        var result = getObject(path);

        if (result == null || JSONObject.NULL.equals(result)) {
            result = EasyJSONObject.generate();
        }

        return result;
    }


    /**
     * 通过对象判断是否为基本类型
     * @param object
     * @return
     */
    static bool isPrimitiveType(Object object) {
        // Dart 内置了七种类型：Number、String、Boolean、List、Map、Runes、Symbol；
        return object is num || object is String ||
                object is bool || object is List ||
                object is Map || object is Runes;
    }



    @override
    String toString() {
        if (json == null) {
            return "null";
        }

        if (jsonType == JSON_TYPE_OBJECT) {
            var jsonObject = json as JSONObject;
            return jsonObject.toString();
        } else if (jsonType == JSON_TYPE_ARRAY) {
            var jsonArray = json as JSONArray;
            return jsonArray.toString();
        }

        return "null";
    }

    /**
     * 以格式化的形式输出json字符串
     * @param indentSpaces 缩进空格数
     * @return
     */
    String toPrettyString(int indentSpaces) {
        if (json == null) {
            return "null";
        }

        var jsonString = "null";
        try {
            if (jsonType == JSON_TYPE_OBJECT) {
                var jsonObject = json as JSONObject;
                jsonString = jsonObject.toPrettyString(indentSpaces);
            } else if (jsonType == JSON_TYPE_ARRAY) {
                var jsonArray = json as JSONArray;
                jsonString = jsonArray.toPrettyString(indentSpaces);
            }
        } catch (e) {
        }

        return jsonString;
    }
}



/*
EasyJSONObject和EasyJOSNArray都支持path路径的访问
关于路径path的说明，以下面的JSON为例(通过测试)

{
	"code": 200,
	"message": "success",
	"valid": true,
	"pi": 3.14,
	"data": {
		"phone": 10086,
		"addr": "China",
		"score": {
			"math": 95,
			"music": 86
		},
		"bool_list": [false, true, false]
	},
	"int_list": [1, 2, 3, 4],
	"string_list": ["Tom", "Peter", "Jack"],
	"hybrid_list": [1, {
		"http_not_found": 404
	}, "toyota"],
	"object_list": [{
		"lang": "java",
		"type": "static"
	}, {
		"lang": "javascript",
		"type": "dynamic"
	}],
	"multi_dim": [
		[0, 1],
		[2, 3]
	]
}


------------------------------------------------------------------
路径                 |值
------------------------------------------------------------------
code                |int(200)
------------------------------------------------------------------
data                |EasyJSONObject对象
------------------------------------------------------------------
data.score.math     |int(95)
------------------------------------------------------------------
int_list            |EasyJSONArray对象
------------------------------------------------------------------
int_list[2]         |int(3)
------------------------------------------------------------------
object_list[0]      |EasyJSONObject对象
------------------------------------------------------------------
object_list[0].lang |string("java")
------------------------------------------------------------------
multi_dim[0][1]     |int(3)
------------------------------------------------------------------



对于EasyJSONArray，还支持通过index访问其中的元素(通过测试)
[
	200,
	"success",
	true,
	3.14, [1, {
		"http_not_found": 404
	}, "toyota"],
	{
		"math": 95,
		"music": 86
	},
	[{
		"lang": "java",
		"type": "static"
	}, {
		"lang": "javascript",
		"type": "dynamic"
	}],
	[
		[0, 1],
		[2, 3]
	]
]


------------------------------------------------------------------
索引                 |值
------------------------------------------------------------------
0                   |int(200)
------------------------------------------------------------------
1                   |string("success")
------------------------------------------------------------------
4                   |EasyJSONArray对象
------------------------------------------------------------------
5                   |EasyJSONObject对象
------------------------------------------------------------------



 */