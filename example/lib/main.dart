import 'package:hson_dart/hson_dart.dart';

void main() async {
  String hsonPath = "../hson/sample.hson";

  var h = await HSON.getInstance("../");

  await h.writeHSON<Map<String, String>>({"foo": "bar"}, hsonPath);

  print(await h.readHSON(hsonPath));
}
