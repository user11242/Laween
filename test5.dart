import 'dart:convert';
void main() {
  var s = String.fromCharCode(0xD83D);
  try {
    var encoded = utf8.encode(s);
    var decoded = utf8.decode(encoded, allowMalformed: true);
    print(decoded == '\uFFFD');
  } catch (e) {
    print("THREW");
  }
}
