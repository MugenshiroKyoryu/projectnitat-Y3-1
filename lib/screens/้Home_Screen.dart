import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:pdfx/pdfx.dart';
import 'package:permission_handler/permission_handler.dart';

import 'PdfViewScreen.dart';
import 'CbzViewScreen.dart';
import 'package:workshopfinal/models/data.dart';

/// ----------------
/// ชั้นนอก HomeScreen
/// ----------------
class HomeScreen
    extends
        StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<
    HomeScreen
  >
  createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends
        State<
          HomeScreen
        > {
  List<
    Series
  >
  seriesList =
      [];

  /// ขอ permission สำหรับอ่านไฟล์
  Future<
    void
  >
  requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      return;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "ต้องการสิทธิ์เข้าถึงไฟล์",
          ),
        ),
      );
    }
  }

  /// เลือกหลายไฟล์แล้วรวมไว้ใน Playlist เดียว
  Future<
    void
  >
  pickFiles() async {
    await requestPermissions();

    FilePickerResult?
    result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'cbz',
      ],
      allowCompression: false,
      withData: false,
    );

    if (result !=
        null) {
      List<
        String
      >
      allFiles = [];

      for (var file in result.files) {
        if (file.path !=
            null) {
          allFiles.add(
            file.path!,
          );
        }
      }

      setState(
        () {
          if (allFiles.isNotEmpty) {
            // ✅ ตั้งชื่อ playlist ใหม่ทุกครั้ง
            final newTitle = "Playlist ${seriesList.length + 1}";
            seriesList.add(
              Series(
                title: newTitle,
                files: allFiles,
              ),
            );
          }
        },
      );
    }
  }

  /// สร้าง thumbnail จากไฟล์ PDF หรือ CBZ
  Future<
    Widget
  >
  buildThumbnail(
    String
    path,
  ) async {
    if (path.endsWith(
      '.pdf',
    )) {
      final doc = await PdfDocument.openFile(
        path,
      );
      final page = await doc.getPage(
        1,
      );
      final pageImage = await page.render(
        width: 300,
        height: 400,
      );
      if (pageImage !=
          null) {
        return Image.memory(
          pageImage.bytes,
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Text(
              "โหลดภาพไม่ได้",
            ),
          ),
        );
      }
    } else if (path.endsWith(
      '.cbz',
    )) {
      final files = await _extractCbzForThumbnail(
        path,
      );
      if (files.isNotEmpty) {
        return Image.file(
          files.first,
          fit: BoxFit.cover,
        );
      }
    }

    return Container(
      color: Colors.grey[300],
    );
  }

  /// ฟังก์ชัน extract เฉพาะสำหรับ thumbnail (เอาแค่ไฟล์แรก)
  Future<
    List<
      File
    >
  >
  _extractCbzForThumbnail(
    String
    cbzPath,
  ) async {
    final bytes = await File(
      cbzPath,
    ).readAsBytes();
    final archive = ZipDecoder().decodeBytes(
      bytes,
    );
    final tempDir =
        await getTemporaryDirectory();

    final cbzName = cbzPath
        .split(
          '/',
        )
        .last
        .replaceAll(
          '.cbz',
          '',
        );
    final extractDir = Directory(
      '${tempDir.path}/$cbzName-thumb',
    );
    if (!await extractDir.exists()) {
      await extractDir.create(
        recursive: true,
      );
    }

    List<
      File
    >
    imageFiles =
        [];
    for (final file
        in archive) {
      if (file.isFile) {
        final filename = '${extractDir.path}/${file.name}';
        final outFile = File(
          filename,
        );
        await outFile.create(
          recursive: true,
        );
        await outFile.writeAsBytes(
          file.content
              as List<
                int
              >,
        );
        imageFiles.add(
          outFile,
        );
        break; // ✅ เอาแค่ไฟล์แรกพอทำ thumbnail
      }
    }
    return imageFiles;
  }

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ชั้นหนังสือ",
        ),
      ),
      body: seriesList.isEmpty
          ? const Center(
              child: Text(
                "กด + เพื่อเพิ่มไฟล์",
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(
                8,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: seriesList.length,
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final series = seriesList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (
                                  _,
                                ) => SeriesDetailScreen(
                                  series: series,
                                ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: series.files.isNotEmpty
                                ? FutureBuilder<
                                    Widget
                                  >(
                                    future: buildThumbnail(
                                      series.files.first,
                                    ),
                                    builder:
                                        (
                                          context,
                                          snapshot,
                                        ) {
                                          if (snapshot.hasData) return snapshot.data!;
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Text(
                                        "ไม่มีไฟล์",
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            series.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder:
                (
                  BuildContext context,
                ) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file,
                          ),
                          title: const Text(
                            "เพิ่มไฟล์",
                          ),
                          onTap: () {
                            Navigator.pop(
                              context,
                            );
                            pickFiles(); // ใช้ฟังก์ชันใหม่
                          },
                        ),
                      ],
                    ),
                  );
                },
          );
        },
        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),
    );
  }
}

/// ----------------
/// ชั้นใน SeriesDetailScreen
/// ----------------
class SeriesDetailScreen
    extends
        StatefulWidget {
  final Series
  series;
  const SeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  State<
    SeriesDetailScreen
  >
  createState() =>
      _SeriesDetailScreenState();
}

class _SeriesDetailScreenState
    extends
        State<
          SeriesDetailScreen
        > {
  Future<
    List<
      File
    >
  >
  extractCbz(
    String
    cbzPath,
  ) async {
    final bytes = await File(
      cbzPath,
    ).readAsBytes();
    final archive = ZipDecoder().decodeBytes(
      bytes,
    );
    final tempDir =
        await getTemporaryDirectory();

    // ✅ แยกโฟลเดอร์เฉพาะแต่ละ cbz
    final cbzName = cbzPath
        .split(
          '/',
        )
        .last
        .replaceAll(
          '.cbz',
          '',
        );
    final extractDir = Directory(
      '${tempDir.path}/$cbzName',
    );
    if (!await extractDir.exists()) {
      await extractDir.create(
        recursive: true,
      );
    }

    List<
      File
    >
    imageFiles =
        [];
    for (final file
        in archive) {
      if (file.isFile) {
        final filename = '${extractDir.path}/${file.name}';
        final outFile = File(
          filename,
        );
        await outFile.create(
          recursive: true,
        );
        await outFile.writeAsBytes(
          file.content
              as List<
                int
              >,
        );
        imageFiles.add(
          outFile,
        );
      }
    }
    return imageFiles;
  }

  Future<
    void
  >
  addFilesToPlaylist() async {
    FilePickerResult?
    result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'cbz',
      ],
      allowCompression: false,
      withData: false,
    );

    if (result !=
        null) {
      List<
        String
      >
      newFiles = [];
      for (var file in result.files) {
        if (file.path !=
            null)
          newFiles.add(
            file.path!,
          );
      }

      setState(
        () {
          widget.series.files.addAll(
            newFiles,
          ); // ✅ เพิ่มไฟล์เข้า playlist นี้
        },
      );
    }
  }

  Future<
    Widget
  >
  buildThumbnail(
    String
    path,
  ) async {
    if (path.endsWith(
      '.pdf',
    )) {
      final doc = await PdfDocument.openFile(
        path,
      );
      final page = await doc.getPage(
        1,
      );
      final pageImage = await page.render(
        width: 120,
        height: 160,
      );
      if (pageImage !=
          null) {
        return Image.memory(
          pageImage.bytes,
          fit: BoxFit.cover,
        );
      }
    } else if (path.endsWith(
      '.cbz',
    )) {
      final files = await extractCbz(
        path,
      );
      if (files.isNotEmpty) {
        return Image.file(
          files.first,
          fit: BoxFit.cover,
        );
      }
    }
    return Container(
      color: Colors.grey[300],
    );
  }

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.series.title,
        ),
      ),
      body: widget.series.files.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีไฟล์ในซีรีส์นี้",
              ),
            )
          : ListView.builder(
              itemCount: widget.series.files.length,
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final path = widget.series.files[index];
                    final fileName = path
                        .split(
                          '/',
                        )
                        .last;
                    return ListTile(
                      leading:
                          FutureBuilder<
                            Widget
                          >(
                            future: buildThumbnail(
                              path,
                            ),
                            builder:
                                (
                                  context,
                                  snapshot,
                                ) {
                                  if (snapshot.hasData) return snapshot.data!;
                                  return const SizedBox(
                                    width: 50,
                                    child: CircularProgressIndicator(),
                                  );
                                },
                          ),
                      title: Text(
                        fileName,
                      ),
                      onTap: () async {
                        if (path.endsWith(
                          '.pdf',
                        )) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (
                                    _,
                                  ) => PdfViewScreen(
                                    path: path,
                                  ),
                            ),
                          );
                        } else if (path.endsWith(
                          '.cbz',
                        )) {
                          final images = await extractCbz(
                            path,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (
                                    _,
                                  ) => CbzViewScreen(
                                    images: images,
                                  ),
                            ),
                          );
                        }
                      },
                    );
                  },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addFilesToPlaylist, // ✅ ปุ่ม + เพิ่มไฟล์
        backgroundColor: Colors.deepPurple,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
