class Series {
  String
  title; // เอา final ออก
  final List<
    String
  >
  files; // เก็บ path ของไฟล์ในซีรีส์

  Series({
    required this.title,
    required this.files,
  });
}
