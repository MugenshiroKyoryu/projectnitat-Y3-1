import 'dart:io';

class Series {
  final String
  title;
  final List<
    FileSystemEntity
  >
  files; // list ของ pdf/cbz
  Series({
    required this.title,
    required this.files,
  });
}
