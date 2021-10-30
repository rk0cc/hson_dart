/// HSON reader and writer package
///
/// This package is not included library, please get these on
/// [HSON release](https://github.com/rk0cc/hson/releases/)
library hson_dart;

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

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

typedef _ReadHSON = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> path);
typedef _WriteHSON = ffi.Int32 Function(
    ffi.Pointer<Utf8> context, ffi.Pointer<Utf8> path);

typedef _DReadHSON = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> path);
typedef _DWriteHSON = int Function(
    ffi.Pointer<Utf8> context, ffi.Pointer<Utf8> path);

/// ### Hash checked JSON storage in Dart implementation
///
/// This is HSON in Dart implememtation
///
/// The library binary is not included in this package
class HSON {
  static HSON? _instance;
  static String? _currentOpenPath;
  final ffi.DynamicLibrary _dl;

  HSON._(this._dl);

  _DReadHSON get _nativeRead =>
      _dl.lookup<ffi.NativeFunction<_ReadHSON>>("readHSON").asFunction();

  _DWriteHSON get _nativeWrite =>
      _dl.lookup<ffi.NativeFunction<_WriteHSON>>("writeHSON").asFunction();

  /// Get the instance of [HSON]
  ///
  /// The [HSON]'s library must be stored at the root directory of the
  /// executable project
  ///
  /// Provide [libPath] that to override location of HSON library directory
  /// and default uses the location that executing program
  ///
  /// Default [libPath] value is current directory for Windows and
  /// `/lib/hson` for most UNIX system
  static Future<HSON> getInstance([String? libPath]) => Future(() {
        if (_instance == null ||
            (_currentOpenPath != libPath && _instance != null)) {
          _currentOpenPath = p.join(
              libPath ??
                  (Platform.isWindows
                      ? Directory.current.path
                      : "/${p.join("usr", "lib", "hson")}"),
              _dlName);
          _instance = HSON._(ffi.DynamicLibrary.open(_currentOpenPath!));
        }
        return _instance!;
      });

  /// Read the [HSON] context from [hsonPath]
  ///
  /// Throws [HSONFileException] if the returned enpty [String]
  /// from library
  ///
  /// The return type of [readHSON] can be either [List] or [Map]
  Future<dynamic> readHSON(String hsonPath) => Future(() {
        try {
          String ctx = _nativeRead(hsonPath.toNativeUtf8()).toDartString();
          assert(ctx != "");
          return jsonDecode(ctx);
        } catch (_) {
          throw HSONFileException.read(hsonPath);
        }
      });

  /// Writing [context] to [hsonPath]
  ///
  /// Throws [HSONFileException] if the exit returned non zero value
  Future<void> writeHSON<J>(J context, String hsonPath) => Future(() {
        assert(context is Map<String, dynamic> || context is List<dynamic>);
        int resErr = _nativeWrite(
            jsonEncode(context).toNativeUtf8(), hsonPath.toNativeUtf8());
        if (resErr != 0) {
          throw HSONFileException.write(hsonPath, resErr);
        }
      });
}
