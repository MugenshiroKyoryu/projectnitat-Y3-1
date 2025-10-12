import 'dart:io'; // ใช้จัดการไฟล์ เช่น อ่านไฟล์, สร้างไฟล์
import 'package:flutter/material.dart'; // ใช้สร้าง UI ของ Flutter
import 'package:path_provider/path_provider.dart'; // ใช้หาพาธของโฟลเดอร์เครื่อง เช่น temp
import 'package:archive/archive_io.dart'; // ใช้แตกไฟล์ .cbz (zip)
import 'package:workshopfinal/models/data.dart'; // ใช้เรียกข้อมูลโมเดล Series ของเรา

// กำหนด enum สำหรับโหมดการอ่าน
enum ReadingMode {
  vertical, // ค่าเริ่มต้น สไลด์ลง
  leftToRight, // เลื่อนหน้าจอจากซ้ายไปขวา
  rightToLeft, // เลื่อนหน้าจอจากขวาไปซ้าย
}

// หน้าจอสำหรับอ่านไฟล์ CBZ (comic book zip)
class CbzViewScreen
    extends
        StatefulWidget {
  final Series
  series; // ข้อมูลซีรีส์ทั้งหมด
  final int
  currentIndex; // บทที่กำลังอ่าน
  final List<
    File
  >
  images; // รายการภาพของตอนนั้น

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
  currentIndex; // บทปัจจุบัน
  late List<
    File
  >
  currentImages; // ภาพของบทปัจจุบัน
  bool
  _isUiVisible =
      true; // แสดง/ซ่อน UI
  ReadingMode
  _readingMode =
      ReadingMode.vertical; // โหมดการอ่านเริ่มต้น

  Key
  _viewKey =
      UniqueKey(); // ใช้รีเฟรช view เมื่อเปลี่ยนบท
  final PageController
  _pageController =
      PageController(); // ควบคุม PageView สำหรับเลื่อนภาพ

  @override
  void
  initState() {
    super.initState();
    currentIndex =
        widget.currentIndex;
    currentImages =
        widget.images;
  }

  @override
  void
  dispose() {
    _pageController.dispose(); // ล้างตัวควบคุม PageView
    super.dispose();
  }

  // ฟังก์ชันแตกไฟล์ CBZ เป็นไฟล์ภาพ
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
    ).readAsBytes(); // อ่านไฟล์ .cbz เป็น bytes
    final archive = ZipDecoder().decodeBytes(
      bytes,
    ); // แตก zip
    final tempDir =
        await getTemporaryDirectory(); // โฟลเดอร์ชั่วคราว

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
      ); // สร้างโฟลเดอร์ถ้าไม่มี
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
        ); // สร้างไฟล์
        await outFile.writeAsBytes(
          file.content
              as List<
                int
              >,
        ); // เขียนเนื้อหา
        imageFiles.add(
          outFile,
        ); // เก็บลง list
      }
    }
    return imageFiles;
  }

  // ไปบทถัดไป
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
            _viewKey = UniqueKey(); // รีเฟรช view
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

  // ไปบทก่อนหน้า
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
            _viewKey = UniqueKey(); // รีเฟรช view
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

  // แสดงเมนูเลือกบท
  void
  showChaptersMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(
        0xFF1E1E1E,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            16,
          ),
        ),
      ),
      builder:
          (
            context,
          ) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: widget.series.files.length,
              separatorBuilder:
                  (
                    context,
                    index,
                  ) => const Divider(
                    color: Colors.grey,
                    height: 1,
                  ),
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final chapterName = "Chapter ${index + 1}";
                    final isCurrent =
                        index ==
                        currentIndex;

                    return ListTile(
                      leading: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        chapterName,
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.orange
                              : Colors.white,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(
                          context,
                        );
                        final selectedPath = widget.series.files[index];
                        if (selectedPath.endsWith(
                          ".cbz",
                        )) {
                          final images = await extractCbz(
                            selectedPath,
                          );
                          setState(
                            () {
                              currentIndex = index;
                              currentImages = images;
                              _viewKey = UniqueKey(); // รีเฟรช view
                            },
                          );
                        }
                      },
                    );
                  },
            );
          },
    );
  }

  // สร้าง widget แสดงภาพตามโหมดการอ่าน
  Widget
  imageView() {
    switch (_readingMode) {
      case ReadingMode.vertical: // scroll ลง
        return Container(
          color: Colors.black,
          child: ListView.builder(
            key: _viewKey,
            itemCount: currentImages.length,
            itemBuilder:
                (
                  context,
                  index,
                ) => Image.file(
                  currentImages[index],
                ),
          ),
        );

      case ReadingMode.leftToRight: // เลื่อนซ้าย→ขวา
      case ReadingMode.rightToLeft: // เลื่อนขวา→ซ้าย
        return PageView.builder(
          key: _viewKey,
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          reverse:
              _readingMode ==
              ReadingMode.rightToLeft, // สลับทิศทาง
          itemCount: currentImages.length,
          itemBuilder:
              (
                context,
                index,
              ) => Image.file(
                currentImages[index],
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

    return GestureDetector(
      onTap: () {
        setState(
          () {
            _isUiVisible = !_isUiVisible; // แตะเพื่อซ่อน/โชว์ UI
          },
        );
      },
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF4EDF5,
        ),
        appBar: _isUiVisible
            ? AppBar(
                backgroundColor: const Color(
                  0xFF1E1E1E,
                ),
                title: Text(
                  fileName,
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                iconTheme: const IconThemeData(
                  color: Colors.orange,
                ),
                actions: [
                  // ปุ่มเปลี่ยนโหมดการอ่าน
                  PopupMenuButton<
                    ReadingMode
                  >(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    tooltip: 'เปลี่ยนโหมดการอ่าน',
                    color: const Color(
                      0xFF1E1E1E,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    onSelected:
                        (
                          mode,
                        ) {
                          setState(
                            () {
                              _readingMode = mode;
                              _viewKey = UniqueKey(); // รีเฟรช view
                            },
                          );
                          Future.delayed(
                            const Duration(
                              milliseconds: 100,
                            ),
                            () {
                              if (_readingMode !=
                                  ReadingMode.vertical) {
                                _pageController.jumpToPage(
                                  0,
                                ); // เริ่มหน้าแรก
                              }
                            },
                          );
                        },
                    itemBuilder:
                        (
                          context,
                        ) => [
                          PopupMenuItem(
                            value: ReadingMode.vertical,
                            child: _buildMenuItem(
                              Icons.swap_vert,
                              "โหมดสไลด์ลง (ค่าเริ่มต้น)",
                              _readingMode ==
                                  ReadingMode.vertical,
                            ),
                          ),
                          PopupMenuItem(
                            value: ReadingMode.rightToLeft,
                            child: _buildMenuItem(
                              Icons.keyboard_arrow_left,
                              "โหมดสไลด์ ขวา → ซ้าย",
                              _readingMode ==
                                  ReadingMode.rightToLeft,
                            ),
                          ),
                          PopupMenuItem(
                            value: ReadingMode.leftToRight,
                            child: _buildMenuItem(
                              Icons.keyboard_arrow_right,
                              "โหมดสไลด์ ซ้าย → ขวา",
                              _readingMode ==
                                  ReadingMode.leftToRight,
                            ),
                          ),
                        ],
                  ),
                ],
              )
            : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: imageView(),
            ), // แสดงภาพเต็มหน้าจอ
            if (_isUiVisible)
              Positioned(
                left: 20,
                bottom: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  child: Row(
                    children: [
                      // ปุ่มเปิดเมนูบท
                      Container(
                        color: Colors.orange,
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                          ),
                          onPressed: showChaptersMenu,
                        ),
                      ),
                      // ปุ่มย้อนกลับบท
                      Container(
                        color: const Color(
                          0xFF1E1E1E,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: goToPrevious,
                        ),
                      ),
                      // ปุ่มไปบทถัดไป
                      Container(
                        color: const Color(
                          0xFF1E1E1E,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                          onPressed: goToNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // สร้าง row ของไอคอน + ข้อความ สำหรับเมนู
  Widget
  _buildMenuItem(
    IconData
    icon,
    String
    text,
    bool
    active,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: active
              ? Colors.orange
              : Colors.white70,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: active
                  ? Colors.orange
                  : Colors.white,
              fontWeight: active
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
