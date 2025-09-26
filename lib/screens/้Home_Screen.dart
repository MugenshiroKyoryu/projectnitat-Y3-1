import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:pdfx/pdfx.dart'; // ใช้ pdfx

import 'PdfViewScreen.dart';
import 'CbzViewScreen.dart';

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
    String
  >
  filePaths =
      []; // เก็บ path ไฟล์ที่เลือก

  Future<
    void
  >
  pickFile(
    BuildContext
    context,
  ) async {
    FilePickerResult?
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'cbz',
      ],
    );

    if (result !=
        null) {
      String
      filePath = result.files.single.path!;
      setState(
        () {
          filePaths.add(
            filePath,
          ); // เก็บ path ไฟล์
        },
      );
    }
  }

  Future<
    List<
      File
    >
  >
  extractCbz(
    String
    cbzPath,
  ) async {
    final bytes = File(
      cbzPath,
    ).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(
      bytes,
    );

    final tempDir =
        await getTemporaryDirectory();
    List<
      File
    >
    imageFiles =
        [];

    for (final file
        in archive) {
      if (file.isFile) {
        final data =
            file.content
                as List<
                  int
                >;
        final filename = '${tempDir.path}/${file.name}';
        File(
          filename,
        )..writeAsBytesSync(
          data,
        );
        imageFiles.add(
          File(
            filename,
          ),
        );
      }
    }

    return imageFiles;
  }

  /// สร้าง preview thumbnail จากไฟล์
  Future<
    Widget
  >
  _buildThumbnail(
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
      ); // หน้าแรก

      // ต้องใส่ width และ height
      final pageImage = await page.render(
        width: 300,
        height: 400,
      );

      if (pageImage !=
          null) {
        return Image.memory(
          pageImage.bytes,
          height: 200,
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          height: 200,
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
      List<
        File
      >
      images = await extractCbz(
        path,
      );
      if (images.isNotEmpty) {
        return Image.file(
          images.first,
          height: 200,
          fit: BoxFit.cover,
        );
      }
    }

    // fallback
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Icon(
        Icons.insert_drive_file,
        size: 60,
      ),
    );
  }

  Widget
  buildFileItem(
    String
    path,
  ) {
    String
    fileName = path
        .split(
          '/',
        )
        .last;

    return FutureBuilder<
      Widget
    >(
      future: _buildThumbnail(
        path,
      ),
      builder:
          (
            context,
            snapshot,
          ) {
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: InkWell(
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
                    List<
                      File
                    >
                    images = await extractCbz(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    snapshot.hasData
                        ? snapshot.data!
                        : Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(
                        8.0,
                      ),
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        title: const Text(
          'ชั้นหนังสือ',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: filePaths.isEmpty
          ? const Center(
              child: Text(
                'กดปุ่ม + เพื่อเลือกไฟล์',
              ),
            )
          : ListView.builder(
              itemCount: filePaths.length,
              itemBuilder:
                  (
                    _,
                    index,
                  ) => buildFileItem(
                    filePaths[index],
                  ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => pickFile(
          context,
        ),
        backgroundColor: Colors.deepPurple,
        child: const Icon(
          Icons.add,
          size: 40,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
