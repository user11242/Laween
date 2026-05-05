import 'dart:convert';

class GroupModel {
  String name;
  GroupModel({required this.name});
  
  static String _sanitize(dynamic input) {
    if (input == null) return '';
    String str = input.toString();
    List<int> cleanUnits = [];
    for (int i = 0; i < str.length; i++) {
      int c = str.codeUnitAt(i);
      if (c >= 0xD800 && c <= 0xDBFF) { // High surrogate
        if (i + 1 < str.length) {
          int n = str.codeUnitAt(i + 1);
          if (n >= 0xDC00 && n <= 0xDFFF) { // Valid pair
            cleanUnits.add(c);
            cleanUnits.add(n);
            i++;
          } else {
            cleanUnits.add(0xFFFD); // Replacement char
          }
        } else {
          cleanUnits.add(0xFFFD); // Replacement char
        }
      } else if (c >= 0xDC00 && c <= 0xDFFF) { // Unpaired low surrogate
        cleanUnits.add(0xFFFD); // Replacement char
      } else {
        cleanUnits.add(c);
      }
    }
    return String.fromCharCodes(cleanUnits);
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      name: _sanitize(map['name']) ?? '',
    );
  }
}

void main() {
  var map = { 'name': String.fromCharCode(0xD83D) + "E" };
  var group = GroupModel.fromMap(map);
  print(group.name.codeUnits.map((u) => u.toRadixString(16)).toList());
}
