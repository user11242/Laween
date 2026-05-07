import 'dart:convert';
void main() {
  var s = "${String.fromCharCode(0xD83D)}E";
  try {
    var encoded = utf8.encode(s);
    print("SUCCESS");
  } catch (e) {
    print("THREW: $e");
  }
}
