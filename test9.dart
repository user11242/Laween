void main() {
  String str = String.fromCharCode(0xD83D) + "E";
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
  var sanitized = String.fromCharCodes(cleanUnits);
  print(sanitized.codeUnits.map((u) => u.toRadixString(16)).toList());
}
