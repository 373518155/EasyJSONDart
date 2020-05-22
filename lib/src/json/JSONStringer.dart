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

import '../EasyJSONException.dart';
import 'Ascii.dart';
import 'JSONArray.dart';
import 'JSONObject.dart';

/**
 * Lexical scoping elements within this stringer, necessary to insert the
 * appropriate separator characters (ie. commas and colons) and to detect
 * nesting errors.
 */
enum Scope {

    /**
     * An array with no elements requires no separators or newlines before
     * it is closed.
     */
    EMPTY_ARRAY,

    /**
     * A array with at least one value requires a comma and newline before
     * the next element.
     */
    NONEMPTY_ARRAY,

    /**
     * An object with no keys or values requires no separators or newlines
     * before it is closed.
     */
    EMPTY_OBJECT,

    /**
     * An object whose most recent element is a key. The next element must
     * be a value.
     */
    DANGLING_KEY,

    /**
     * An object with at least one name/value pair requires a comma and
     * newline before the next element.
     */
    NONEMPTY_OBJECT,

    /**
     * A special bracketless array needed by JSONStringer.join() and
     * JSONObject.quote() only. Not used for JSON encoding.
     */
    NULL,
}

/**
 * Implements {@link JSONObject#toString} and {@link JSONArray#toString}. Most
 * application developers should use those methods directly and disregard this
 * API. For example:<pre>
 * JSONObject object = ...
 * String json = object.toString();</pre>
 *
 * <p>Stringers only encode well-formed JSON strings. In particular:
 * <ul>
 *   <li>The stringer must have exactly one top-level array or object.
 *   <li>Lexical scopes must be balanced: every call to {@link #array} must
 *       have a matching call to {@link #endArray} and every call to {@link
 *       #object} must have a matching call to {@link #endObject}.
 *   <li>Arrays may not contain keys (property names).
 *   <li>Objects must alternate keys (property names) and values.
 *   <li>Values are inserted with either literal {@link #value(Object) value}
 *       calls, or by nesting arrays or objects.
 * </ul>
 * Calls that would result in a malformed JSON string will fail with a
 * {@link EasyJSONException}.
 *
 * <p>This class provides no facility for pretty-printing (ie. indenting)
 * output. To encode indented output, use {@link JSONObject#toString(int)} or
 * {@link JSONArray#toString(int)}.
 *
 * <p>Some implementations of the API support at most 20 levels of nesting.
 * Attempts to create more than 20 levels of nesting may fail with a {@link
 * EasyJSONException}.
 *
 * <p>Each stringer may be used to encode a single top level value. Instances of
 * this class are not thread safe. Although this class is nonfinal, it was not
 * designed for inheritance and should not be subclassed. In particular,
 * self-use by overrideable methods is not specified. See <i>Effective Java</i>
 * Item 17, "Design and Document or inheritance or else prohibit it" for further
 * information.
 */
class JSONStringer {

    /** The output data, containing at most one top-level array or object. */
    final StringBuffer out = StringBuffer();

    /**
     * Unlike the original implementation, this stack isn't limited to 20
     * levels of nesting.
     */
    final List<Scope> stack = List<Scope>();

    /**
     * A string containing a full set of spaces for a single level of
     * indentation, or null for no pretty printing.
     */
    String indent;

    JSONStringer([int indentSpaces]) {
        if (indentSpaces == null) {
            indent = null;
        } else {
            var sb = StringBuffer();
            for (var i = 0; i < indentSpaces; i++) {
                sb.write(' ');
            }
            indent = sb.toString();
        }

    }

    /**
     * Begins encoding a new array. Each call to this method must be paired with
     * a call to {@link #endArray}.
     *
     * @return this stringer.
     */
    JSONStringer array() {
        return open(Scope.EMPTY_ARRAY, "[");
    }

    /**
     * Ends encoding the current array.
     *
     * @return this stringer.
     */
    JSONStringer endArray() {
        return close(Scope.EMPTY_ARRAY, Scope.NONEMPTY_ARRAY, "]");
    }

    /**
     * Begins encoding a new object. Each call to this method must be paired
     * with a call to {@link #endObject}.
     *
     * @return this stringer.
     */
    JSONStringer object() {
        return open(Scope.EMPTY_OBJECT, "{");
    }

    /**
     * Ends encoding the current object.
     *
     * @return this stringer.
     */
    JSONStringer endObject() {
        return close(Scope.EMPTY_OBJECT, Scope.NONEMPTY_OBJECT, "}");
    }

    /**
     * Enters a new scope by appending any necessary whitespace and the given
     * bracket.
     */
    JSONStringer open(Scope empty, String openBracket) {
        if (stack.isEmpty && out.length > 0) {
            throw EasyJSONException("Nesting problem: multiple top-level roots");
        }
        beforeValue();
        stack.add(empty);
        out.write(openBracket);
        return this;
    }

    /**
     * Closes the current scope by appending any necessary whitespace and the
     * given bracket.
     */
    JSONStringer close(Scope empty, Scope nonempty, String closeBracket) {
        Scope context = peek();
        if (context != nonempty && context != empty) {
            throw EasyJSONException("Nesting problem");
        }

        stack.removeAt(stack.length - 1);
        if (context == nonempty) {
            newline();
        }
        out.write(closeBracket);
        return this;
    }

    /**
     * Returns the value on the top of the stack.
     */
    Scope peek() {
        if (stack.isEmpty) {
            throw EasyJSONException("Nesting problem");
        }
        return stack[stack.length - 1];
    }

    /**
     * Replace the value on the top of the stack with the given value.
     */
    void replaceTop(Scope topOfStack) {
        stack[stack.length - 1] = topOfStack;
    }

    /**
     * Encodes {@code value}.
     *
     * @param value a {@link JSONObject}, {@link JSONArray}, String, Boolean,
     *     Integer, Long, Double or null. May not be {@link Double#isNaN() NaNs}
     *     or {@link Double#isInfinite() infinities}.
     * @return this stringer.
     */
    JSONStringer value(Object value) {
        if (stack.isEmpty) {
            throw EasyJSONException("Nesting problem");
        }

        if (value is JSONArray) {
            value.writeTo(this);
            return this;

        } else if (value is JSONObject) {
            value.writeTo(this);
            return this;
        }

        beforeValue();

        if (value == null
                || value is bool
                || value == JSONObject.NULL) {
            out.write(value);

        } else if (value is num) {
            out.write(JSONObject.numberToString(value));

        } else {
            string(value.toString());
        }

        return this;
    }

    void string(String value) {
        out.write("\"");
        for (var i = 0, length = value.length; i < length; i++) {
            var c = value.codeUnitAt(i);

            /*
             * From RFC 4627, "All Unicode characters may be placed within the
             * quotation marks except for the characters that must be escaped:
             * quotation mark, reverse solidus, and the control characters
             * (U+0000 through U+001F)."
             */
            switch (c) {
                case Ascii.CODE_DOUBLE_QUOTES: // 双引号 "
                case Ascii.CODE_BACK_SLASH: // 反斜杠 \
                    out.write('\\');
                    out.write(String.fromCharCode(c));
                    break;

                case Ascii.CODE_HT:
                    out.write("\\t");
                    break;

                case Ascii.CODE_BS:
                    out.write("\\b");
                    break;

                case Ascii.CODE_LF:
                    out.write("\\n");
                    break;

                case Ascii.CODE_CR:
                    out.write("\\r");
                    break;

                case Ascii.CODE_FF:
                    out.write("\\f");
                    break;

                default:
                    out.write(String.fromCharCode(c));
                    break;
            }

        }
        out.write("\"");
    }

    void newline() {
        if (indent == null) {
            return;
        }

        out.write("\n");
        for (var i = 0; i < stack.length; i++) {
            out.write(indent);
        }
    }

    /**
     * Encodes the key (property name) to this stringer.
     *
     * @param name the name of the forthcoming value. May not be null.
     * @return this stringer.
     */
    JSONStringer key(String name) {
        if (name == null) {
            throw EasyJSONException("Names must be non-null");
        }
        beforeKey();
        string(name);
        return this;
    }

    /**
     * Inserts any necessary separators and whitespace before a name. Also
     * adjusts the stack to expect the key's value.
     */
    void beforeKey() {
        Scope context = peek();
        if (context == Scope.NONEMPTY_OBJECT) { // first in object
            out.write(',');
        } else if (context != Scope.EMPTY_OBJECT) { // not in an object!
            throw EasyJSONException("Nesting problem");
        }
        newline();
        replaceTop(Scope.DANGLING_KEY);
    }

    /**
     * Inserts any necessary separators and whitespace before a literal value,
     * inline array, or inline object. Also adjusts the stack to expect either a
     * closing bracket or another element.
     */
    void beforeValue() {
        if (stack.isEmpty) {
            return;
        }

        Scope context = peek();
        if (context == Scope.EMPTY_ARRAY) { // first in array
            replaceTop(Scope.NONEMPTY_ARRAY);
            newline();
        } else if (context == Scope.NONEMPTY_ARRAY) { // another in array
            out.write(',');
            newline();
        } else if (context == Scope.DANGLING_KEY) { // value for key
            out.write(indent == null ? ":" : ": ");
            replaceTop(Scope.NONEMPTY_OBJECT);
        } else if (context != Scope.NULL) {
            throw EasyJSONException("Nesting problem");
        }
    }

    /**
     * Returns the encoded JSON string.
     *
     * <p>If invoked with unterminated arrays or unclosed objects, this method's
     * return value is undefined.
     *
     * <p><strong>Warning:</strong> although it contradicts the general contract
     * of {@link Object#toString}, this method returns null if the stringer
     * contains no data.
     */
    @override String toString() {
        return out.length == 0 ? null : out.toString();
    }
}
