import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
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
      [];

  Future<
    void
  >
  pickFile(
    BuildContext
    context,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'cbz',
        ],
      );

      if (result !=
              null &&
          result.files.single.path !=
              null) {
        setState(
          () {
            filePaths.add(
              result.files.single.path!,
            );
          },
        );
      }
    } catch (
      e
    ) {
      debugPrint(
        "Error picking file: $e",
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "เกิดข้อผิดพลาดในการเลือกไฟล์",
          ),
        ),
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
    try {
      final bytes = File(
        cbzPath,
      ).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(
        bytes,
      );

      final tempDir = await getTemporaryDirectory();
      List<
        File
      >
      imageFiles = [];

      for (final file in archive) {
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
    } catch (
      e
    ) {
      debugPrint(
        "Error extracting CBZ: $e",
      );
      return [];
    }
  }

  Widget
  buildFileItem(
    String
    path,
  ) {
    final fileName = path
        .split(
          '/',
        )
        .last;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: ListTile(
        leading: Icon(
          path.endsWith(
                '.pdf',
              )
              ? Icons.picture_as_pdf
              : Icons.image,
          color: Colors.deepPurple,
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
            if (images.isNotEmpty) {
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
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    "ไม่สามารถเปิดไฟล์ CBZ ได้",
                  ),
                ),
              );
            }
          }
        },
      ),
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
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
