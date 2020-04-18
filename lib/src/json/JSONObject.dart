/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */



// Note: this class was written without inspecting the non-free org.json sourcecode.

import 'dart:collection';
import 'dart:core';

import '../EasyJSONArray.dart';
import '../EasyJSONException.dart';
import '../EasyJSONObject.dart';
import 'JSON.dart';
import 'JSONArray.dart';
import 'JSONStringer.dart';
import 'JSONTokener.dart';

class JSONObjectNULL {
    bool equals(Object o) {
        return o == this || o == null; // API specifies this broken equals implementation
    }
    @override String toString() {
        return "null";
    }
}

/**
 * A modifiable set of name/value mappings. Names are unique, non-null strings.
 * Values may be any mix of {@link JSONObject JSONObjects}, {@link JSONArray
 * JSONArrays}, Strings, Booleans, Integers, Longs, Doubles or {@link #NULL}.
 * Values may not be {@code null}, {@link Double#isNaN() NaNs}, {@link
 * Double#isInfinite() infinities}, or of any type not listed here.
 *
 * <p>This class can coerce values to another type when requested.
 * <ul>
 *   <li>When the requested type is a boolean, strings will be coerced using a
 *       case-insensitive comparison to "true" and "false".
 *   <li>When the requested type is a double, other {@link Number} types will
 *       be coerced using {@link Number#doubleValue() doubleValue}. Strings
 *       that can be coerced using {@link Double#valueOf(String)} will be.
 *   <li>When the requested type is an int, other {@link Number} types will
 *       be coerced using {@link Number#intValue() intValue}. Strings
 *       that can be coerced using {@link Double#valueOf(String)} will be,
 *       and then cast to int.
 *   <li><a name="lossy">When the requested type is a long, other {@link Number} types will
 *       be coerced using {@link Number#longValue() longValue}. Strings
 *       that can be coerced using {@link Double#valueOf(String)} will be,
 *       and then cast to long. This two-step conversion is lossy for very
 *       large values. For example, the string "9223372036854775806" yields the
 *       long 9223372036854775807.</a>
 *   <li>When the requested type is a String, other non-null values will be
 *       coerced using {@link String#valueOf(Object)}. Although null cannot be
 *       coerced, the sentinel value {@link JSONObject#NULL} is coerced to the
 *       string "null".
 * </ul>
 *
 * <p>This class can look up both mandatory and optional values:
 * <ul>
 *   <li>Use <code>get<i>Type</i>()</code> to retrieve a mandatory value. This
 *       fails with a {@code EasyJSONException} if the requested name has no value
 *       or if the value cannot be coerced to the requested type.
 *   <li>Use <code>opt<i>Type</i>()</code> to retrieve an optional value. This
 *       returns a system- or user-supplied default if the requested name has no
 *       value or if the value cannot be coerced to the requested type.
 * </ul>
 *
 * <p><strong>Warning:</strong> this class represents null in two incompatible
 * ways: the standard Java {@code null} reference, and the sentinel value {@link
 * JSONObject#NULL}. In particular, calling {@code put(name, null)} removes the
 * named entry from the object but {@code put(name, JSONObject.NULL)} stores an
 * entry whose value is {@code JSONObject.NULL}.
 *
 * <p>Instances of this class are not thread safe. Although this class is
 * nonfinal, it was not designed for inheritance and should not be subclassed.
 * In particular, self-use by overrideable methods is not specified. See
 * <i>Effective Java</i> Item 17, "Design and Document or inheritance or else
 * prohibit it" for further information.
 */
class JSONObject {

    static final double NEGATIVE_ZERO = -0;

    /**
     * A sentinel value used to explicitly define a name with no value. Unlike
     * {@code null}, names with this value:
     * <ul>
     *   <li>show up in the {@link #names} array
     *   <li>show up in the {@link #keys} iterator
     *   <li>return {@code true} for {@link #has(String)}
     *   <li>do not throw on {@link #get(String)}
     *   <li>are included in the encoded JSON string.
     * </ul>
     *
     * <p>This value violates the general contract of {@link Object#equals} by
     * returning true when compared to {@code null}. Its {@link #toString}
     * method returns "null".
     */
    static final JSONObjectNULL NULL = JSONObjectNULL();

    HashMap<String, Object> nameValuePairs;



    /**
     * Creates a new {@code JSONObject} with name/value mappings from the JSON
     * string.
     *
     * @param json a JSON-encoded string containing an object.
     * @throws EasyJSONException if the parse fails or doesn't yield a {@code
     *     JSONObject}.
     */
    JSONObject({String json, Map<String, Object> map}) {
        if (json == null && map == null) { // 如果没有指定，则构造空对象
            nameValuePairs = HashMap();
            return;
        }

        if (json != null) {
            var jsonTokener = JSONTokener(json);

            /*
         * Getting the parser to populate this could get tricky. Instead, just
         * parse to temporary JSONObject and then steal the data from that.
         */

            var object = jsonTokener.nextValue();
            if (object is JSONObject) {
                nameValuePairs = object.nameValuePairs;
            } else {
                throw JSON.typeMismatch(object, "JSONObject");
            }
        } else if (map != null) {
            nameValuePairs = HashMap();
            map.forEach((String key, Object value) {
                nameValuePairs[key] = value;
            });
        }

    }



    /**
     * Returns the number of name/value mappings in this object.
     */
    int length() {
        return nameValuePairs.length;
    }

    /**
     * Maps {@code name} to {@code value}, clobbering any existing name/value
     * mapping with the same name. If the value is {@code null}, any existing
     * mapping for {@code name} is removed.
     *
     * @param value a {@link JSONObject}, {@link JSONArray}, String, Boolean,
     *     Integer, Long, Double, {@link #NULL}, or {@code null}. May not be
     *     {@link Double#isNaN() NaNs} or {@link Double#isInfinite()
     *     infinities}.
     * @return this object.
     */
    JSONObject put(String name, Object value) {
        if (value == null) {
            nameValuePairs.remove(name);
            return this;
        }
        if (value is double) {
            // deviate from the original by checking all Numbers, not just floats & doubles
            JSON.checkDouble(value);
        }
        nameValuePairs[checkName(name)] = value;
        return this;
    }

    /**
     * Equivalent to {@code put(name, value)} when both parameters are non-null;
     * does nothing otherwise.
     */
    JSONObject putOpt(String name, Object value) {
        if (name == null || value == null) {
            return this;
        }
        return put(name, value);
    }

    /**
     * Appends {@code value} to the array already mapped to {@code name}. If
     * this object has no mapping for {@code name}, this inserts a new mapping.
     * If the mapping exists but its value is not an array, the existing
     * and new values are inserted in order into a new array which is itself
     * mapped to {@code name}. In aggregate, this allows values to be added to a
     * mapping one at a time.
     *
     * <p> Note that {@code append(String, Object)} provides better semantics.
     * In particular, the mapping for {@code name} will <b>always</b> be a
     * {@link JSONArray}. Using {@code accumulate} will result in either a
     * {@link JSONArray} or a mapping whose type is the type of {@code value}
     * depending on the number of calls to it.
     *
     * @param value a {@link JSONObject}, {@link JSONArray}, String, Boolean,
     *     Integer, Long, Double, {@link #NULL} or null. May not be {@link
     *     Double#isNaN() NaNs} or {@link Double#isInfinite() infinities}.
     */
    // TODO: Change {@code append) to {@link #append} when append is
    // unhidden.
    JSONObject accumulate(String name, Object value) {
        var current = nameValuePairs[checkName(name)];
        if (current == null) {
            return put(name, value);
        }

        if (current is JSONArray) {
            current.checkedPut(value);
        } else {
            var array = JSONArray();
            array.checkedPut(current);
            array.checkedPut(value);
            nameValuePairs[name] = array;
        }
        return this;
    }

    /**
     * Appends values to the array mapped to {@code name}. A new {@link JSONArray}
     * mapping for {@code name} will be inserted if no mapping exists. If the existing
     * mapping for {@code name} is not a {@link JSONArray}, a {@link EasyJSONException}
     * will be thrown.
     *
     * @throws EasyJSONException if {@code name} is {@code null} or if the mapping for
     *         {@code name} is non-null and is not a {@link JSONArray}.
     *
     * @hide
     */
    JSONObject append(String name, Object value) {
        var current = nameValuePairs[checkName(name)];

        JSONArray array;
        if (current is JSONArray) {
            array = current;
        } else if (current == null) {
            var newArray = JSONArray();
            nameValuePairs[name] = newArray;
            array = newArray;
        } else {
            throw EasyJSONException("Key " + name + " is not a JSONArray");
        }

        array.checkedPut(value);

        return this;
    }

    String checkName(String name) {
        if (name == null) {
            throw EasyJSONException("Names must be non-null");
        }
        return name;
    }

    /**
     * Removes the named mapping if it exists; does nothing otherwise.
     *
     * @return the value previously mapped by {@code name}, or null if there was
     *     no such mapping.
     */
    Object remove(String name) {
        return nameValuePairs.remove(name);
    }

    /**
     * Returns true if this object has no mapping for {@code name} or if it has
     * a mapping whose value is {@link #NULL}.
     */
    bool isNull(String name) {
        var value = nameValuePairs[name];
        return value == null || value == NULL;
    }

    /**
     * Returns true if this object has a mapping for {@code name}. The mapping
     * may be {@link #NULL}.
     */
    bool has(String name) {
        return nameValuePairs.containsKey(name);
    }

    /**
     * Returns the value mapped by {@code name}, or throws if no such mapping exists.
     *
     * @throws EasyJSONException if no such mapping exists.
     */
    Object get(String name) {
        var result = nameValuePairs[name];
        if (result == null) {
            throw EasyJSONException("No value for " + name);
        }
        return result;
    }

    /**
     * Returns the value mapped by {@code name}, or null if no such mapping
     * exists.
     */
    Object opt(String name) {
        return nameValuePairs[name];
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is a boolean or
     * can be coerced to a boolean, or throws otherwise.
     *
     * @throws EasyJSONException if the mapping doesn't exist or cannot be coerced
     *     to a boolean.
     */
    bool getBoolean(String name) {
        var object = get(name);
        var result = JSON.toBoolean(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "boolean", indexOrName: name);
        }
        return result;
    }



    /**
     * Returns the value mapped by {@code name} if it exists and is a boolean or
     * can be coerced to a boolean, or {@code fallback} otherwise.
     */
    bool optBoolean(String name, bool fallback) {
        var object = opt(name);
        var result = JSON.toBoolean(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is a double or
     * can be coerced to a double, or throws otherwise.
     *
     * @throws EasyJSONException if the mapping doesn't exist or cannot be coerced
     *     to a double.
     */
    double getDouble(String name) {
        var object = get(name);
        var result = JSON.toDouble(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "double", indexOrName: name);
        }
        return result;
    }


    /**
     * Returns the value mapped by {@code name} if it exists and is a double or
     * can be coerced to a double, or {@code fallback} otherwise.
     */
    double optDouble(String name, double fallback) {
        var object = opt(name);
        var result = JSON.toDouble(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is an int or
     * can be coerced to an int, or throws otherwise.
     *
     * @throws EasyJSONException if the mapping doesn't exist or cannot be coerced
     *     to an int.
     */
    int getInt(String name) {
        var object = get(name);
        var result = JSON.toInteger(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "int", indexOrName: name);
        }
        return result;
    }



    /**
     * Returns the value mapped by {@code name} if it exists and is an int or
     * can be coerced to an int, or {@code fallback} otherwise.
     */
    int optInt(String name, int fallback) {
        var object = opt(name);
        var result = JSON.toInteger(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value mapped by {@code name} if it exists, coercing it if
     * necessary, or throws if no such mapping exists.
     *
     * @throws EasyJSONException if no such mapping exists.
     */
    String getString(String name) {
        var object = get(name);
        var result = JSON.convertToString(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "String", indexOrName: name);
        }
        return result;
    }

    /**
     * Returns the value mapped by {@code name} if it exists, coercing it if
     * necessary, or {@code fallback} if no such mapping exists.
     */
    String optString(String name, String fallback) {
        var object = opt(name);
        var result = JSON.convertToString(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is a {@code
     * JSONArray}, or throws otherwise.
     *
     * @throws EasyJSONException if the mapping doesn't exist or is not a {@code
     *     JSONArray}.
     */
    JSONArray getJSONArray(String name) {
        var object = get(name);
        if (object is JSONArray) {
            return object;
        } else {
            throw JSON.typeMismatch(object, "JSONArray", indexOrName: name);
        }
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is a {@code
     * JSONArray}, or null otherwise.
     */
    JSONArray optJSONArray(String name) {
        var object = opt(name);
        return object is JSONArray ? object : null;
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is a {@code
     * JSONObject}, or throws otherwise.
     *
     * @throws EasyJSONException if the mapping doesn't exist or is not a {@code
     *     JSONObject}.
     */
    JSONObject getJSONObject(String name) {
        var object = get(name);
        if (object is JSONObject) {
            return object;
        } else {
            throw JSON.typeMismatch(object, "JSONObject", indexOrName: name);
        }
    }

    /**
     * Returns the value mapped by {@code name} if it exists and is a {@code
     * JSONObject}, or null otherwise.
     */
    JSONObject optJSONObject(String name) {
        var object = opt(name);
        return object is JSONObject ? object : null;
    }

    /**
     * Returns an array with the values corresponding to {@code names}. The
     * array contains null for names that aren't mapped. This method returns
     * null if {@code names} is either null or empty.
     */
    JSONArray toJSONArray(JSONArray names) {
        var result = JSONArray();
        if (names == null) {
            return null;
        }
        var length = names.length();
        if (length == 0) {
            return null;
        }
        for (var i = 0; i < length; i++) {
            var name = JSON.convertToString(names.opt(i));
            result.put(opt(name));
        }
        return result;
    }

    /**
     * Returns an iterator of the {@code String} names in this object. The
     * returned iterator supports {@link Iterator#remove() remove}, which will
     * remove the corresponding mapping from this object. If this object is
     * modified after the iterator is returned, the iterator's behavior is
     * undefined. The order of the keys is undefined.
     */
    Iterable<String> keys() {
        return nameValuePairs.keys;
    }


    Iterable<MapEntry<String, Object>> entrySet() {
        return nameValuePairs.entries;
    }



    /**
     * Encodes this object as a compact JSON string, such as:
     * <pre>{"query":"Pizza","locations":[94043,90210]}</pre>
     */
    @override String toString() {
        try {
            var stringer = JSONStringer();
            writeTo(stringer);
            return stringer.toString();
        } catch (e) {
            return null;
        }
    }

    /**
     * Encodes this object as a human readable JSON string for debugging, such
     * as:
     * <pre>
     * {
     *     "query": "Pizza",
     *     "locations": [
     *         94043,
     *         90210
     *     ]
     * }</pre>
     *
     * @param indentSpaces the number of spaces to indent for each level of
     *     nesting.
     */
    String toPrettyString(int indentSpaces) {
        var stringer = JSONStringer(indentSpaces);
        writeTo(stringer);
        return stringer.toString();
    }

    void writeTo(JSONStringer stringer) {
        stringer.object();

        nameValuePairs.entries.forEach((entry) {
            stringer.key(entry.key).value(entry.value);
        });

        stringer.endObject();
    }

    /**
     * Encodes the number as a JSON string.
     *
     * @param number a finite value. May not be {@link Double#isNaN() NaNs} or
     *     {@link Double#isInfinite() infinities}.
     */
    static String numberToString(num number) {
        if (number == null) {
            throw EasyJSONException("Number must be non-null");
        }

        if (number is double) {
            var doubleValue = number as double;
            JSON.checkDouble(doubleValue);

            // the original returns "-0" instead of "-0.0" for negative zero
            if (doubleValue == NEGATIVE_ZERO) {
                return "-0";
            }
        }

        return number.toString();
    }

    /**
     * Encodes {@code data} as a JSON string. This applies quotes and any
     * necessary character escaping.
     *
     * @param data the string to encode. Null will be interpreted as an empty
     *     string.
     */
    static String quote(String data) {
        if (data == null) {
            return "\"\"";
        }
        try {
            var stringer = JSONStringer();
            stringer.open(Scope.NULL, "");
            stringer.value(data);
            stringer.close(Scope.NULL, Scope.NULL, "");
            return stringer.toString();
        } catch (e) {
            throw AssertionError();
        }
    }

    /**
     * Wraps the given object if necessary.
     *
     * <p>If the object is null or , returns {@link #NULL}.
     * If the object is a {@code JSONArray} or {@code JSONObject}, no wrapping is necessary.
     * If the object is {@code NULL}, no wrapping is necessary.
     * If the object is an array or {@code Collection}, returns an equivalent {@code JSONArray}.
     * If the object is a {@code Map}, returns an equivalent {@code JSONObject}.
     * If the object is a primitive wrapper type or {@code String}, returns the object.
     * Otherwise if the object is from a {@code java} package, returns the result of {@code toString}.
     * If wrapping fails, returns null.
     */
    static Object wrap(Object o) {
        if (o == null) {
            return NULL;
        }

        if (o is EasyJSONArray) {  // 类型转换
            o = (o as EasyJSONArray).getJSONArray();
        }
        if (o is EasyJSONObject) {  // 类型转换
            o = (o as EasyJSONObject).getJSONObject();
        }
        if (o is JSONArray || o is JSONObject) {
            return o;
        }
        if (NULL.equals(o)) {
            return o;
        }
        try {
            if (o is Iterable) {
                return JSONArray(iterable: o);
            }
            if (o is Map) {
                return JSONObject(map : o);
            }
            if (o is bool ||
                o is Runes ||
                o is double ||
                o is int ||
                o is String) {
                return o;
            }
            return o.toString();
        } catch (ignored) {
        }
        return null;
    }

    HashMap<String, Object> getHashMap() {
        return nameValuePairs;
    }
}
