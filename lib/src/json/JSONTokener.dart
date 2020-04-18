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



import 'dart:core';

import '../EasyJSONException.dart';
import 'Ascii.dart';
import 'JSONArray.dart';
import 'JSONObject.dart';

class JSONTokener {

    /** The input JSON. */
    String input;

    /**
     * The index of the next character to be returned by {@link #next}. When
     * the input is exhausted, this equals the input's length.
     */
    int pos = 0;

    /**
     * @param in JSON encoded string. Null is not permitted and will yield a
     *     tokener that throws {@code NullPointerExceptions} when methods are
     *     called.
     */
    JSONTokener(String input) {
        // consume an optional byte order mark (BOM) if it exists
        if (input != null && input.startsWith("\ufeff")) {
            input = input.substring(1);
        }
        this.input = input;
    }

    /**
     * Returns the next value from the input.
     *
     * @return a {@link JSONObject}, {@link JSONArray}, String, Boolean,
     *     Integer, Long, Double or {@link JSONObject#NULL}.
     * @throws EasyJSONException if the input is malformed.
     */
    Object nextValue() {
        var c = nextCleanInternal();

        switch (c) {
            case -1:
                throw syntaxError("End of input");

            case Ascii.CODE_LEFT_CURLY_BRACKET: // 左大括号 {
                return readObject();

            case Ascii.CODE_LEFT_SQUARE_BRACKET: // 左中括号 [
                return readArray();

            case Ascii.CODE_SINGLE_QUOTES: // 单引号 '
                return nextString('\'');
            case Ascii.CODE_DOUBLE_QUOTES: // 双引号 "
                return nextString('"');

            default:
                pos--;
                return readLiteral();
        }
    }

    int nextCleanInternal() {
        while (pos < input.length) {
            var c = input.codeUnitAt(pos++);
            switch (c) {
                case Ascii.CODE_HT: // \t
                case Ascii.CODE_SPACE: // 空格
                case Ascii.CODE_LF: // 换行
                case Ascii.CODE_CR: // 回车
                    continue;

                case Ascii.CODE_SLASH: // 斜杠 /
                    if (pos == input.length) {
                        return c;
                    }

                    var peek = input.codeUnitAt(pos);
                    switch (peek) {
                        case Ascii.CODE_ASTERISK: // 星号 *
                            // skip a /* c-style comment */
                            pos++;
                            var commentEnd = input.indexOf("*/", pos);
                            if (commentEnd == -1) {
                                throw syntaxError("Unterminated comment");
                            }
                            pos = commentEnd + 2;
                            continue;

                        case Ascii.CODE_SLASH: // 斜杠 /
                            // skip a // end-of-line comment
                            pos++;
                            skipToEndOfLine();
                            continue;

                        default:
                            return c;
                    }
                    break;
                case Ascii.CODE_HASH: // 井号 #
                    /*
                     * Skip a # hash end-of-line comment. The JSON RFC doesn't
                     * specify this behavior, but it's required to parse
                     * existing documents. See http://b/2571423.
                     */
                    skipToEndOfLine();
                    continue;

                default:
                    return c;
            }
        }

        return -1;
    }

    /**
     * Advances the position until after the next newline character. If the line
     * is terminated by "\r\n", the '\n' must be consumed as whitespace by the
     * caller.
     */
    void skipToEndOfLine() {
        for (; pos < input.length; pos++) {
            var c = input[pos];
            if (c == '\r' || c == '\n') {
                pos++;
                break;
            }
        }
    }

    /**
     * Returns the string up to but not including {@code quote}, unescaping any
     * character escape sequences encountered along the way. The opening quote
     * should have already been read. This consumes the closing quote, but does
     * not include it in the returned string.
     *
     * @param quote either ' or ".
     */
    String nextString(String quote) {
        /*
         * For strings that are free of escape sequences, we can just extract
         * the result as a substring of the input. But if we encounter an escape
         * sequence, we need to use a StringBuilder to compose the result.
         */
        var builder = StringBuffer();

        /* the index of the first character not yet appended to the builder. */
        var start = pos;

        while (pos < input.length) {
            var c = input[pos++];
            if (c == quote) {
                if (builder == null) {
                    // a new string avoids leaking memory
                    return input.substring(start, pos - 1);
                } else {
                    builder.write(input.substring(start, pos - 1));
                    return builder.toString();
                }
            }

            if (c == '\\') {
                if (pos == input.length) {
                    throw syntaxError("Unterminated escape sequence");
                }
                builder ??= StringBuffer();
                builder.write(input.substring(start, pos - 1));
                builder.write(readEscapeCharacter());
                start = pos;
            }
        }

        throw syntaxError("Unterminated string");
    }

    /**
     * Unescapes the character identified by the character or characters that
     * immediately follow a backslash. The backslash '\' should have already
     * been read. This supports both unicode escapes "u000A" and two-character
     * escapes "\n".
     */
    String readEscapeCharacter() {
        var escaped = input[pos++];
        switch (escaped) {
            case 'u':
                if (pos + 4 > input.length) {
                    throw syntaxError("Unterminated escape sequence");
                }
                var hex = input.substring(pos, pos + 4);
                pos += 4;

                var codeUnit = int.parse(hex, radix: 16, onError: (String source)  {
                    throw syntaxError("Invalid escape sequence: " + hex);
                });
                return String.fromCharCode(codeUnit);
                break;
            case 't':
                return '\t';

            case 'b':
                return '\b';

            case 'n':
                return '\n';

            case 'r':
                return '\r';

            case 'f':
                return '\f';

            case '\'':
            case '"':
            case '\\':
            default:
                return escaped;
        }
    }

    /**
     * Reads a null, boolean, numeric or unquoted string literal value. Numeric
     * values will be returned as an Integer, Long, or Double, in that order of
     * preference.
     */
    Object readLiteral() {
        var literal = nextToInternal("{}[]/\\:,=;# \t\f");

        if (literal.length == 0) {
            throw syntaxError("Expected literal value");
        } else if ("null" == literal) {
            return JSONObject.NULL;
        } else if ("true" == literal) {
            return true;
        } else if ("false" == literal) {
            return false;
        }

        /* try to parse as an integral type... */
        if (literal.indexOf('.') == -1) {
            var base = 10;
            var number = literal;
            if (number.startsWith("0x") || number.startsWith("0X")) {
                number = number.substring(2);
                base = 16;
            } else if (number.startsWith("0") && number.length > 1) {
                number = number.substring(1);
                base = 8;
            }

            return int.tryParse(number, radix: base);
        }

        /* ...next try to parse as a floating point... */
        return double.tryParse(literal);


        /* ... finally give up. We have an unquoted string */
        // return new String(literal); // a new string avoids leaking memory
    }

    /**
     * Returns the string up to but not including any of the given characters or
     * a newline character. This does not consume the excluded character.
     */
    String nextToInternal(String excluded) {
        var start = pos;
        for (; pos < input.length; pos++) {
            var c = input[pos];
            if (c == '\r' || c == '\n' || excluded.indexOf(c) != -1) {
                return input.substring(start, pos);
            }
        }
        return input.substring(start);
    }

    /**
     * Reads a sequence of key/value pairs and the trailing closing brace '}' of
     * an object. The opening brace '{' should have already been read.
     */
    JSONObject readObject() {
        var result = JSONObject();

        /* Peek to see if this is the empty object. */
        var first = nextCleanInternal();
        if (first == Ascii.CODE_RIGHT_CURLY_BRACKET) { // 右花括号 }
            return result;
        } else if (first != -1) {
            pos--;
        }

        while (true) {
            var name = nextValue();
            if (!(name is String)) {
                if (name == null) {
                    throw syntaxError("Names cannot be null");
                } else {
                    throw syntaxError("Names must be strings, but " + name
                            + " is of type " + name.runtimeType.toString());
                }
            }
            /*
             * Expect the name/value separator to be either a colon ':', an
             * equals sign '=', or an arrow "=>". The last two are bogus but we
             * include them because that's what the original implementation did.
             */
            var separator = nextCleanInternal();
            if (separator != Ascii.CODE_COLON &&  // 冒号 :
                separator != Ascii.CODE_EQUAL) { // 等于号 =
                throw syntaxError("Expected ':' after " + name);
            }
            if (pos < input.length && input[pos] == '>') {
                pos++;
            }
            result.put(name as String, nextValue());

            switch (nextCleanInternal()) {
                case Ascii.CODE_RIGHT_CURLY_BRACKET: // 右大括号 }
                    return result;
                case Ascii.CODE_SEMICOLON: // 分号 ;
                case Ascii.CODE_COMMA: // 逗号 ,
                    continue;
                default:
                    throw syntaxError("Unterminated object");
            }
        }
    }

    /**
     * Reads a sequence of values and the trailing closing brace ']' of an
     * array. The opening brace '[' should have already been read. Note that
     * "[]" yields an empty array, but "[,]" returns a two-element array
     * equivalent to "[null,null]".
     */
    JSONArray readArray() {
        var result = JSONArray();

        /* to cover input that ends with ",]". */
        var hasTrailingSeparator = false;

        while (true) {
            switch (nextCleanInternal()) {
                case -1:
                    throw syntaxError("Unterminated array");
                case Ascii.CODE_RIGHT_SQUARE_BRACKET: // 右中括号 ]
                    if (hasTrailingSeparator) {
                        result.put(null);
                    }
                    return result;
                case Ascii.CODE_COMMA: // 逗号 ,
                case Ascii.CODE_SEMICOLON: // 分号 ;
                    /* A separator without a value first means "null". */
                    result.put(null);
                    hasTrailingSeparator = true;
                    continue;
                default:
                    pos--;
            }

            result.put(nextValue());

            switch (nextCleanInternal()) {
                case Ascii.CODE_RIGHT_SQUARE_BRACKET: // 右中括号 ]
                    return result;
                case Ascii.CODE_COMMA: // 逗号 ,
                case Ascii.CODE_SEMICOLON: // 分号 ;
                    hasTrailingSeparator = true;
                    continue;
                default:
                    throw syntaxError("Unterminated array");
            }
        }
    }

    /**
     * Returns an exception containing the given message plus the current
     * position and the entire input string.
     */
    EasyJSONException syntaxError(String message) {
        return EasyJSONException(message + toString());
    }

    /**
     * Returns the current position and the entire input string.
     */
    @override
    String toString() {
        // consistent with the original implementation
        return " at character " + pos.toString() + " of " + input;
    }

    /*
     * Legacy APIs.
     *
     * None of the methods below are on the critical path of parsing JSON
     * documents. They exist only because they were exposed by the original
     * implementation and may be used by some clients.
     */

//    /**
//     * Returns true until the input has been exhausted.
//     */
//    bool more() {
//        return pos < input.length;
//    }
//
//    /**
//     * Returns the next available character, or the null character '\0' if all
//     * input has been exhausted. The return value of this method is ambiguous
//     * for JSON strings that contain the character '\0'.
//     */
//    String next() {
//        return pos < input.length ? input[pos++] : '\0';
//    }
//
//    /**
//     * Returns the next available character if it equals {@code c}. Otherwise an
//     * exception is thrown.
//     */
//    char next(char c) {
//        char result = next();
//        if (result != c) {
//            throw syntaxError("Expected " + c + " but was " + result);
//        }
//        return result;
//    }
//
//    /**
//     * Returns the next character that is not whitespace and does not belong to
//     * a comment. If the input is exhausted before such a character can be
//     * found, the null character '\0' is returned. The return value of this
//     * method is ambiguous for JSON strings that contain the character '\0'.
//     */
//    char nextClean() {
//        int nextCleanInt = nextCleanInternal();
//        return nextCleanInt == -1 ? '\0' : (char) nextCleanInt;
//    }
//
//    /**
//     * Returns the next {@code length} characters of the input.
//     *
//     * <p>The returned string shares its backing character array with this
//     * tokener's input string. If a reference to the returned string may be held
//     * indefinitely, you should use {@code new String(result)} to copy it first
//     * to avoid memory leaks.
//     *
//     * @throws EasyJSONException if the remaining input is not long enough to
//     *     satisfy this request.
//     */
//    String next(int length) {
//        if (pos + length > input.length) {
//            throw syntaxError(length.toString() + " is out of bounds");
//        }
//        String result = input.substring(pos, pos + length);
//        pos += length;
//        return result;
//    }
//
//    /**
//     * Returns the {@link String#trim trimmed} string holding the characters up
//     * to but not including the first of:
//     * <ul>
//     *   <li>any character in {@code excluded}
//     *   <li>a newline character '\n'
//     *   <li>a carriage return '\r'
//     * </ul>
//     *
//     * <p>The returned string shares its backing character array with this
//     * tokener's input string. If a reference to the returned string may be held
//     * indefinitely, you should use {@code new String(result)} to copy it first
//     * to avoid memory leaks.
//     *
//     * @return a possibly-empty string
//     */
//    String nextTo(String excluded) {
//        if (excluded == null) {
//            throw EasyJSONException("NullPointerException!excluded == null");
//        }
//        return nextToInternal(excluded).trim();
//    }
//
//    /**
//     * Equivalent to {@code nextTo(String.valueOf(excluded))}.
//     */
//    String nextTo(char excluded) {
//        return nextToInternal(String.valueOf(excluded)).trim();
//    }
//
//    /**
//     * Advances past all input up to and including the next occurrence of
//     * {@code thru}. If the remaining input doesn't contain {@code thru}, the
//     * input is exhausted.
//     */
//    void skipPast(String thru) {
//        int thruStart = input.indexOf(thru, pos);
//        pos = thruStart == -1 ? input.length : (thruStart + thru.length);
//    }
//
//    /**
//     * Advances past all input up to but not including the next occurrence of
//     * {@code to}. If the remaining input doesn't contain {@code to}, the input
//     * is unchanged.
//     */
//    char skipTo(char to) {
//        int index = input.indexOf(to, pos);
//        if (index != -1) {
//            pos = index;
//            return to;
//        } else {
//            return '\0';
//        }
//    }
//
//    /**
//     * Unreads the most recent character of input. If no input characters have
//     * been read, the input is unchanged.
//     */
//    void back() {
//        if (--pos == -1) {
//            pos = 0;
//        }
//    }

    /**
     * Returns the integer [0..15] value for the given hex character, or -1
     * for non-hex or invalid input.
     *
     * @param hex a character in the ranges [0-9], [A-F] or [a-f]. Any other
     *     character will yield a -1 result.
     */
    static int dehexchar(String hexStr) {
        if (hexStr == null || hexStr.length != 1) { // hexStr必须为单个字符的字符串
            return -1;
        }

        var hex = hexStr.codeUnitAt(0);
        if (hex >= 0x30 /* 0 */ && hex <= 0x39 /* 9 */) {
            return hex - 0x30;
        } else if (hex >= 0x41 /* A */ && hex <= 0x46 /* F */) {
            return hex - 0x41 + 10;
        } else if (hex >= 0x61 /* a */ && hex <= 0x66 /* f */) {
            return hex - 0x61 + 10;
        } else {
            return -1;
        }
    }
}
