import 'package:hson_dart/hson.dart';

void main() {
  var h = HSON.getInstance();

  h.writeHSON<Map<String, String>>({"foo": "bar"}, "sample.hson");

  print(h.readHSON("sample.hson"));
}
