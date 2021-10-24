/// HSON reader and writer package
///
/// This package is not included library, please get these on
/// [HSON release](https://github.com/rk0cc/hson/releases/)
library hson_dart;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

String get _dlName {
  String name = "hson";
  if (Platform.isWindows) {
    return "$name.dll";
  } else if (Platform.isMacOS) {
    return "$name.dylib";
  } else if (Platform.isLinux) {
    return "$name.so";
  } else {
    throw UnsupportedError("This platform is not supported platform of HSON");
  }
}

/// An exception on handling HSON file
class HSONFileException implements FileSystemException {
  final String _msg, _hsonPath;

  /// Craete general [HSONFileException] with [hsonPath]
  ///
  /// And optionally giving [message]
  HSONFileException(String hsonPath, [String? message])
      : _hsonPath = hsonPath,
        _msg = message ?? "There is an error when trying to fetch HSON file";

  /// Encounter [HSONFileException] when reading file
  factory HSONFileException.read(String hsonPath) =>
      HSONFileException(hsonPath, "Can not get context of this HSON file");

  /// Encounter [HSONFileException] when writing file
  factory HSONFileException.write(String hsonPath, int errNo) {
    assert(errNo != 0);
    String errMsg = "";
    switch (errNo) {
      case 1:
        errMsg = "HSON can not generate the context of incoming data";
        break;
      case 2:
        errMsg = "Writing HSON data to file failed";
        break;
    }
    return HSONFileException(hsonPath, errMsg);
  }

  /// Message of exception
  @override
  String get message => _msg;

  /// [OSError] is not required in [HSONFileException]
  @override
  OSError? get osError => null;

  /// Path to HSON
  @override
  String get path => _hsonPath;
}

typedef _ReadHSON = Pointer<Utf8> Function(Pointer<Utf8> path);
typedef _WriteHSON = Int32 Function(Pointer<Utf8> context, Pointer<Utf8> path);

typedef _DReadHSON = Pointer<Utf8> Function(Pointer<Utf8> path);
typedef _DWriteHSON = int Function(Pointer<Utf8> context, Pointer<Utf8> path);

/// ### Hash checked JSON storage in Dart implementation
///
/// This is HSON in Dart implememtation
///
/// The library binary is not included in this package
class HSON {
  static HSON? _instance;
  final DynamicLibrary _dl;

  HSON._(this._dl);

  _DReadHSON get _nativeRead =>
      _dl.lookup<NativeFunction<_ReadHSON>>("readHSON").asFunction();

  _DWriteHSON get _nativeWrite =>
      _dl.lookup<NativeFunction<_WriteHSON>>("writeHSON").asFunction();

  /// Get the instance of [HSON]
  ///
  /// The [HSON]'s library must be stored at the root directory of the
  /// executable project
  static HSON getInstance() {
    if (_instance == null) {
      _instance = HSON._(DynamicLibrary.open(_dlName));
    }
    return _instance!;
  }

  /// Read the [HSON] context from [hsonPath]
  ///
  /// Throws [HSONFileException] if the returned enpty [String]
  /// from library
  ///
  /// The return type of [readHSON] can be either [List] or [Map]
  readHSON(String hsonPath) {
    try {
      String ctx = _nativeRead(hsonPath.toNativeUtf8()).toDartString();
      assert(ctx != "");
      return jsonDecode(ctx);
    } catch (_) {
      throw HSONFileException.read(hsonPath);
    }
  }

  /// Writing [context] to [hsonPath]
  ///
  /// Throws [HSONFileException] if the exit returned non zero value
  void writeHSON<J>(J context, String hsonPath) {
    assert(context is Map<String, dynamic> || context is List<dynamic>);
    int resErr = _nativeWrite(
        jsonEncode(context).toNativeUtf8(), hsonPath.toNativeUtf8());
    if (resErr != 0) {
      throw HSONFileException.write(hsonPath, resErr);
    }
  }
}
