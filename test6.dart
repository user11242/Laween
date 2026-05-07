import 'package:characters/characters.dart';
void main() {
  var s = "${String.fromCharCode(0xD83D)}E";
  print(s.characters.first.codeUnits.map((u) => u.toRadixString(16)).toList());
}
