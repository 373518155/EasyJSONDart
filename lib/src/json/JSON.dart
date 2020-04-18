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


import '../EasyJSONException.dart';

class JSON {
    static final String STR_EMPTY_OBJECT = '{}'; // 表示空对象的字符串
    static final String STR_EMPTY_ARRAY = '[]';  // 表示空数组的字符串

    /**
     * Returns the input if it is a JSON-permissible value; throws otherwise.
     */
    static double checkDouble(double d) {
        if (d.isInfinite || d.isNaN) {
            throw EasyJSONException("Forbidden numeric value: " + d.toString());
        }
        return d;
    }

    static bool toBoolean(Object value) {
        if (value is bool) {
            return value;
        } else if (value is String) {
            var stringValue = value.toLowerCase();
            if ("true" == stringValue) {
                return true;
            } else if ("false" == stringValue) {
                return false;
            }
        }
        return null;
    }

    static double toDouble(Object value) {
        if (value is double) {
            return value;
        } else if (value is num) {
            return value.toDouble();
        } else if (value is String) {
            try {
                return double.tryParse(value);
            } catch (ignored) {
            }
        }
        return null;
    }

    static int toInteger(Object value) {
        if (value is int) {
            return value;
        } else if (value is num) {
            return value.toInt();
        } else if (value is String) {
            try {
                return int.tryParse(value);
            } catch (ignored) {
            }
        }
        return null;
    }

    static String convertToString(Object value) {
        if (value is String) {
            return value;
        } else if (value != null) {
            return value.toString();
        }
        return null;
    }

    static EasyJSONException typeMismatch(Object actual, String requiredType, {Object indexOrName}) {
        if (indexOrName == null) {
            if (actual == null) {
                throw new EasyJSONException("Value is null.");
            } else {
                throw new EasyJSONException("Value " + actual
                    + " of type " + actual.runtimeType.toString()
                    + " cannot be converted to " + requiredType);
            }
        } else {
            if (actual == null) {
                throw EasyJSONException("Value at " + indexOrName + " is null.");
            } else {
                throw new EasyJSONException("Value " + actual + " at " + indexOrName
                    + " of type " + actual.runtimeType.toString()
                    + " cannot be converted to " + requiredType);
            }
        }
    }
}
