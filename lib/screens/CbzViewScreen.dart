import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:workshopfinal/models/data.dart';

class CbzViewScreen
    extends
        StatefulWidget {
  final Series
  series; // ✅ เพลย์ลิสที่มีไฟล์ cbz หลายตอน
  final int
  currentIndex; // ✅ ตอนที่เปิดอยู่
  final List<
    File
  >
  images; // ✅ รูปใน cbz ตอนนี้

  const CbzViewScreen({
    super.key,
    required this.series,
    required this.currentIndex,
    required this.images,
  });

  @override
  State<
    CbzViewScreen
  >
  createState() =>
      _CbzViewScreenState();
}

class _CbzViewScreenState
    extends
        State<
          CbzViewScreen
        > {
  late int
  currentIndex;
  late List<
    File
  >
  currentImages;

  @override
  void
  initState() {
    super.initState();
    currentIndex =
        widget.currentIndex;
    currentImages =
        widget.images;
  }

  /// ฟังก์ชัน extract CBZ (อ่านไฟล์ cbz แล้วแปลงเป็นรูป)
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

  /// ไปตอนถัดไป
  Future<
    void
  >
  goToNext() async {
    if (currentIndex <
        widget.series.files.length -
            1) {
      final nextPath =
          widget.series.files[currentIndex +
              1];
      if (nextPath.endsWith(
        '.cbz',
      )) {
        final nextImages = await extractCbz(
          nextPath,
        );
        setState(
          () {
            currentIndex++;
            currentImages = nextImages;
          },
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "นี่คือตอนสุดท้ายแล้ว",
          ),
        ),
      );
    }
  }

  /// ไปตอนก่อนหน้า
  Future<
    void
  >
  goToPrevious() async {
    if (currentIndex >
        0) {
      final prevPath =
          widget.series.files[currentIndex -
              1];
      if (prevPath.endsWith(
        '.cbz',
      )) {
        final prevImages = await extractCbz(
          prevPath,
        );
        setState(
          () {
            currentIndex--;
            currentImages = prevImages;
          },
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "นี่คือตอนแรกแล้ว",
          ),
        ),
      );
    }
  }

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    final fileName = widget.series.files[currentIndex]
        .split(
          '/',
        )
        .last;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            tooltip: "ตอนก่อนหน้า",
            onPressed: goToPrevious,
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward,
            ),
            tooltip: "ตอนถัดไป",
            onPressed: goToNext,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: currentImages.length,
        itemBuilder:
            (
              context,
              index,
            ) {
              return Image.file(
                currentImages[index],
              );
            },
      ),
    );
  }
}
