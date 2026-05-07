import 'dart:convert';
void main() {
  var s = "${String.fromCharCode(0xD83D)}E";
  var result = utf8.decode(utf8.encode(s), allowMalformed: true);
  print(result.codeUnits.map((u) => u.toRadixString(16)).toList());
}
