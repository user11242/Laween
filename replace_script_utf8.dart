import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('lib/features/groups/pages/chat_page.dart');
  
  // Read UTF-16 from replacement.dart
  final bytes = File('replacement.dart').readAsBytesSync();
  final replacement = utf8.decode(bytes, allowMalformed: true).replaceAll('\x00', '');

  final lines = file.readAsLinesSync();

  int startIdx = -1;
  int endIdx = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('<<<<<<< HEAD') && i > 2480 && i < 2500) {
      startIdx = i;
    }
    if (lines[i].startsWith('>>>>>>> user-work') && i > 2700 && i < 2750) {
      endIdx = i;
    }
  }

  if (startIdx != -1 && endIdx != -1) {
    final newLines = [
      ...lines.sublist(0, startIdx),
      replacement,
      ...lines.sublist(endIdx + 1)
    ];
    file.writeAsStringSync(newLines.join('\n'));
    print('Replaced lines ${startIdx + 1} to ${endIdx + 1}');
  } else {
    print('Failed to find markers: start=$startIdx, end=$endIdx');
  }
}
