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

import 'dart:math';

import '../EasyJSONException.dart';
import 'JSON.dart';
import 'JSONObject.dart';
import 'JSONStringer.dart';
import 'JSONTokener.dart';

/**
 * A dense indexed sequence of values. Values may be any mix of
 * {@link JSONObject JSONObjects}, other {@link JSONArray JSONArrays}, Strings,
 * Booleans, Integers, Longs, Doubles, {@code null} or {@link JSONObject#NULL}.
 * Values may not be {@link Double#isNaN() NaNs}, {@link Double#isInfinite()
 * infinities}, or of any type not listed here.
 *
 * <p>{@code JSONArray} has the same type coercion behavior and
 * optional/mandatory accessors as {@link JSONObject}. See that class'
 * documentation for details.
 *
 * <p><strong>Warning:</strong> this class represents null in two incompatible
 * ways: the standard Java {@code null} reference, and the sentinel value {@link
 * JSONObject#NULL}. In particular, {@code get} fails if the requested index
 * holds the null reference, but succeeds if it holds {@code JSONObject.NULL}.
 *
 * <p>Instances of this class are not thread safe. Although this class is
 * nonfinal, it was not designed for inheritance and should not be subclassed.
 * In particular, self-use by overridable methods is not specified. See
 * <i>Effective Java</i> Item 17, "Design and Document or inheritance or else
 * prohibit it" for further information.
 */
class JSONArray {
    List<Object> values;



    /**
     * Creates a new {@code JSONArray} with values from the JSON string.
     *
     * @param json a JSON-encoded string containing an array.
     * @throws EasyJSONException if the parse fails or doesn't yield a {@code
     *     JSONArray}.
     */
    JSONArray({String json, Iterable iterable}) {
        if (json == null && iterable == null) { // 如果没有指定，则构造空列表
            values = List();
            return;
        }

        if (json != null) {
            var jsonTokener = JSONTokener(json);

            /*
         * Getting the parser to populate this could get tricky. Instead, just
         * parse to temporary JSONArray and then steal the data from that.
         */
            var object = jsonTokener.nextValue();
            if (object is JSONArray) {
                values = object.values;
            } else {
                throw JSON.typeMismatch(object, "JSONArray");
            }
        } else if (iterable != null) {
            values = List();
            iterable.forEach((elem) {
                values.add(elem);
            });
        }
    }



    /**
     * Returns the number of values in this array.
     */
    int length() {
        return values.length;
    }

    /**
     * Appends {@code value} to the end of this array.
     *
     * @param value a {@link JSONObject}, {@link JSONArray}, String, Boolean,
     *     Integer, Long, Double, {@link JSONObject#NULL}, or {@code null}. May
     *     not be {@link Double#isNaN() NaNs} or {@link Double#isInfinite()
     *     infinities}. Unsupported values are not permitted and will cause the
     *     array to be in an inconsistent state.
     * @return this array.
     */
    JSONArray put(Object value) {
        values.add(value);
        return this;
    }

    /**
     * Same as {@link #put}, with added validity checks.
     */
    void checkedPut(Object value) {
        if (value is double) {
            JSON.checkDouble(value);
        }

        put(value);
    }


    /**
     * Sets the value at {@code index} to {@code value}, null padding this array
     * to the required length if necessary. If a value already exists at {@code
     * index}, it will be replaced.
     *
     * @param value a {@link JSONObject}, {@link JSONArray}, String, Boolean,
     *     Integer, Long, Double, {@link JSONObject#NULL}, or {@code null}. May
     *     not be {@link Double#isNaN() NaNs} or {@link Double#isInfinite()
     *     infinities}.
     * @return this array.
     */
    JSONArray putAt(int index, Object value) {
        if (value is double) {
            // deviate from the original by checking all Numbers, not just floats & doubles
            JSON.checkDouble(value);
        }
        while (values.length <= index) {
            values.add(null);
        }
        values[index] = value;
        return this;
    }

    /**
     * Returns true if this array has no value at {@code index}, or if its value
     * is the {@code null} reference or {@link JSONObject#NULL}.
     */
    bool isNull(int index) {
        var value = opt(index);
        return value == null || value == JSONObject.NULL;
    }

    /**
     * Returns the value at {@code index}.
     *
     * @throws EasyJSONException if this array has no value at {@code index}, or if
     *     that value is the {@code null} reference. This method returns
     *     normally if the value is {@code JSONObject#NULL}.
     */
    Object get(int index) {
        try {
            var value = values[index];
            if (value == null) {
                throw EasyJSONException("Value at " + index.toString() + " is null.");
            }
            return value;
        } catch (e) {
            throw EasyJSONException("Index " + index.toString() + " out of range [0.." + values.length.toString() + ")");
        }
    }

    /**
     * Returns the value at {@code index}, or null if the array has no value
     * at {@code index}.
     */
    Object opt(int index) {
        if (index < 0 || index >= values.length) {
            return null;
        }
        return values[index];
    }

    /**
     * Removes and returns the value at {@code index}, or null if the array has no value
     * at {@code index}.
     */
    Object remove(int index) {
        if (index < 0 || index >= values.length) {
            return null;
        }
        return values.removeAt(index);
    }

    /**
     * Returns the value at {@code index} if it exists and is a boolean or can
     * be coerced to a boolean.
     *
     * @throws EasyJSONException if the value at {@code index} doesn't exist or
     *     cannot be coerced to a boolean.
     */
    bool getBoolean(int index) {
        var object = get(index);
        var result = JSON.toBoolean(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "boolean", indexOrName: index);
        }
        return result;
    }

    /**
     * Returns the value at {@code index} if it exists and is a boolean or can
     * be coerced to a boolean. Returns {@code fallback} otherwise.
     */
    bool optBoolean(int index, bool fallback) {
        var object = opt(index);
        var result = JSON.toBoolean(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value at {@code index} if it exists and is a double or can
     * be coerced to a double.
     *
     * @throws EasyJSONException if the value at {@code index} doesn't exist or
     *     cannot be coerced to a double.
     */
    double getDouble(int index) {
        var object = get(index);
        var result = JSON.toDouble(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "double", indexOrName: index);
        }
        return result;
    }

    /**
     * Returns the value at {@code index} if it exists and is a double or can
     * be coerced to a double. Returns {@code fallback} otherwise.
     */
    double optDouble(int index, double fallback) {
        var object = opt(index);
        var result = JSON.toDouble(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value at {@code index} if it exists and is an int or
     * can be coerced to an int.
     *
     * @throws EasyJSONException if the value at {@code index} doesn't exist or
     *     cannot be coerced to a int.
     */
    int getInt(int index) {
        var object = get(index);
        var result = JSON.toInteger(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "int", indexOrName: index);
        }
        return result;
    }

    /**
     * Returns the value at {@code index} if it exists and is an int or
     * can be coerced to an int. Returns {@code fallback} otherwise.
     */
    int optInt(int index, int fallback) {
        var object = opt(index);
        var result = JSON.toInteger(object);
        return result != null ? result : fallback;
    }



    /**
     * Returns the value at {@code index} if it exists, coercing it if
     * necessary.
     *
     * @throws EasyJSONException if no such value exists.
     */
    String getString(int index) {
        var object = get(index);
        var result = JSON.convertToString(object);
        if (result == null) {
            throw JSON.typeMismatch(object, "String", indexOrName: index);
        }
        return result;
    }


    /**
     * Returns the value at {@code index} if it exists, coercing it if
     * necessary. Returns {@code fallback} if no such value exists.
     */
    String optString(int index, String fallback) {
        var object = opt(index);
        var result = JSON.convertToString(object);
        return result != null ? result : fallback;
    }

    /**
     * Returns the value at {@code index} if it exists and is a {@code
     * JSONArray}.
     *
     * @throws EasyJSONException if the value doesn't exist or is not a {@code
     *     JSONArray}.
     */
    JSONArray getJSONArray(int index) {
        var object = get(index);
        if (object is JSONArray) {
            return object;
        } else {
            throw JSON.typeMismatch(object, "JSONArray", indexOrName: index);
        }
    }

    /**
     * Returns the value at {@code index} if it exists and is a {@code
     * JSONArray}. Returns null otherwise.
     */
    JSONArray optJSONArray(int index) {
        var object = opt(index);
        return object is JSONArray ? object : null;
    }

    /**
     * Returns the value at {@code index} if it exists and is a {@code
     * JSONObject}.
     *
     * @throws EasyJSONException if the value doesn't exist or is not a {@code
     *     JSONObject}.
     */
    JSONObject getJSONObject(int index) {
        var object = get(index);
        if (object is JSONObject) {
            return object;
        } else {
            throw JSON.typeMismatch(object, "JSONObject", indexOrName: index);
        }
    }

    /**
     * Returns the value at {@code index} if it exists and is a {@code
     * JSONObject}. Returns null otherwise.
     */
    JSONObject optJSONObject(int index) {
        var object = opt(index);
        return object is JSONObject ? object : null;
    }

    /**
     * Returns a new object whose values are the values in this array, and whose
     * names are the values in {@code names}. Names and values are paired up by
     * index from 0 through to the shorter array's length. Names that are not
     * strings will be coerced to strings. This method returns null if either
     * array is empty.
     */
    JSONObject toJSONObject(JSONArray names) {
        var result = JSONObject();
        var length = min(names.length(), values.length);
        if (length == 0) {
            return null;
        }
        for (var i = 0; i < length; i++) {
            var name = JSON.convertToString(names.opt(i));
            result.put(name, opt(i));
        }
        return result;
    }

    /**
     * Returns a new string by alternating this array's values with {@code
     * separator}. This array's string values are quoted and have their special
     * characters escaped. For example, the array containing the strings '12"
     * pizza', 'taco' and 'soda' joined on '+' returns this:
     * <pre>"12\" pizza"+"taco"+"soda"</pre>
     */
    String join(String separator) {
        var stringer = JSONStringer();
        stringer.open(Scope.NULL, "");
        for (var i = 0, size = values.length; i < size; i++) {
            if (i > 0) {
                stringer.out.write(separator);
            }
            stringer.value(values[i]);
        }
        stringer.close(Scope.NULL, Scope.NULL, "");
        return stringer.out.toString();
    }

    /**
     * Encodes this array as a compact JSON string, such as:
     * <pre>[94043,90210]</pre>
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
     * Encodes this array as a human readable JSON string for debugging, such
     * as:
     * <pre>
     * [
     *     94043,
     *     90210
     * ]</pre>
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
        stringer.array();
        values.forEach((elem) {
            stringer.value(elem);
        });
        stringer.endArray();
    }

    bool equals(Object o) {
        return (o is JSONArray) && o.values == values;
    }

    List<Object> getList() {
        return values;
    }
}
