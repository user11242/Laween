import 'dart:convert';
void main() {
  var s = String.fromCharCode(0xD83D);
  var encoded = utf8.encode(s);
  print(encoded);
  var hex = encoded.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  print("HEX: $hex");
}
