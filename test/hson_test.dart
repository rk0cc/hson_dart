import 'dart:io';

import 'package:hson_dart/hson_dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  String samplePath = p.join("hson", "sample.hson");
  HSON hson = HSON.getInstance();
  late File targetFile;
  late Directory hsonF;
  setUpAll(() async {
    hsonF = Directory("hson");
    if (!(await hsonF.exists())) {
      hsonF = await hsonF.create();
    }
  });
  test("Write test", () async {
    hson.writeHSON<Map<String, String>>({"foo": "bar"}, samplePath);
    targetFile = File(samplePath);
    expect(true, await targetFile.exists());
  });
  test("Read test", () {
    var context = hson.readHSON(samplePath);
    expect(context, equals({"foo": "bar"}));
  });
}
