import 'package:hson_dart/hson_dart.dart';

void main() {
  String hsonPath = "../hson/sample.hson";

  var h = HSON.getInstance("../");

  h.writeHSON<Map<String, String>>({"foo": "bar"}, hsonPath);

  print(h.readHSON(hsonPath));
}
