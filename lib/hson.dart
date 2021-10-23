library hson_dart;

import 'dart:ffi';
import 'package:ffi/ffi.dart';

class HSON {
  static HSON? _instance;
  DynamicLibrary _dl;

  HSON._(this._dl);
}
