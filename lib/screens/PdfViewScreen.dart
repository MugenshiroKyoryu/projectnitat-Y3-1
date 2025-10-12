import 'package:flutter/material.dart'; // ใช้สร้าง UI ของ Flutter
import 'package:pdfx/pdfx.dart'; // ใช้แสดงไฟล์ PDF

// กำหนด enum สำหรับโหมดการอ่าน PDF
enum ReadingMode {
  vertical, // scroll ลง
  leftToRight, // เลื่อนซ้าย → ขวา
  rightToLeft, // เลื่อนขวา → ซ้าย
}

// หน้าจอสำหรับอ่าน PDF
class PdfViewScreen
    extends
        StatefulWidget {
  final String
  path; // path ของไฟล์ PDF
  final List<
    String
  >
  playlist; // รายการไฟล์ PDF ทั้งหมด (สำหรับ navigation)

  const PdfViewScreen({
    required this.path,
    required this.playlist,
    super.key,
  });

  @override
  State<
    PdfViewScreen
  >
  createState() =>
      _PdfViewScreenState();
}

class _PdfViewScreenState
    extends
        State<
          PdfViewScreen
        > {
  PdfControllerPinch?
  _pdfControllerPinch; // Controller สำหรับ pinch zoom
  PdfController?
  _pdfControllerNormal; // Controller สำหรับ scroll ปกติ

  int
      // ignore: unused_field
      _pagesCount =
      0; // จำนวนหน้าทั้งหมดของ PDF

  int
      // ignore: unused_field
      _currentPage =
      1; // หน้าปัจจุบัน
  bool
  _isUiVisible =
      true; // แสดง/ซ่อน UI
  ReadingMode
  _readingMode =
      ReadingMode.vertical; // โหมดการอ่านเริ่มต้น

  @override
  void
  initState() {
    super.initState();
    _initControllers(); // สร้าง controller สำหรับ PDF
    _loadPdfInfo(); // โหลดข้อมูล PDF เช่น จำนวนหน้า
  }

  // สร้าง controller ของ PDF ทั้งแบบ pinch และ normal
  void
  _initControllers() {
    _pdfControllerPinch = PdfControllerPinch(
      document: PdfDocument.openFile(
        widget.path,
      ),
    );
    _pdfControllerNormal = PdfController(
      document: PdfDocument.openFile(
        widget.path,
      ),
    );
  }

  // โหลดข้อมูล PDF เช่น จำนวนหน้า
  void
  _loadPdfInfo() async {
    final doc = await PdfDocument.openFile(
      widget.path,
    );
    setState(() {
      _pagesCount = doc.pagesCount;
    });
  }

  @override
  void
  dispose() {
    _pdfControllerPinch?.dispose(); // ล้าง controller pinch
    _pdfControllerNormal?.dispose(); // ล้าง controller normal
    super.dispose();
  }

  // ไปไฟล์ถัดไปใน playlist
  Future<
    void
  >
  goToNext() async {
    final currentIndex = widget.playlist.indexOf(
      widget.path,
    );
    if (currentIndex <
        widget.playlist.length -
            1) {
      final nextPath =
          widget.playlist[currentIndex +
              1];
      // เปิด PdfViewScreen ของไฟล์ถัดไป
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (
                _,
              ) => PdfViewScreen(
                path: nextPath,
                playlist: widget.playlist,
              ),
        ),
      );
    } else {
      // แสดงข้อความถ้าเป็นไฟล์สุดท้าย
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "นี่คือไฟล์สุดท้ายแล้ว",
          ),
        ),
      );
    }
  }

  // ไปไฟล์ก่อนหน้าใน playlist
  Future<
    void
  >
  goToPrevious() async {
    final currentIndex = widget.playlist.indexOf(
      widget.path,
    );
    if (currentIndex >
        0) {
      final prevPath =
          widget.playlist[currentIndex -
              1];
      // เปิด PdfViewScreen ของไฟล์ก่อนหน้า
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (
                _,
              ) => PdfViewScreen(
                path: prevPath,
                playlist: widget.playlist,
              ),
        ),
      );
    } else {
      // แสดงข้อความถ้าเป็นไฟล์แรก
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "นี่คือไฟล์แรกแล้ว",
          ),
        ),
      );
    }
  }

  // แสดงเมนูเลือกบท (ไฟล์) จาก playlist
  void
  showChaptersMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // พื้นหลังเมนูมืด
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
              itemCount: widget.playlist.length,
              separatorBuilder:
                  (
                    context,
                    index,
                  ) => Divider(
                    color: Colors.grey[700],
                    height: 1,
                  ),
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final isCurrent =
                        widget.path ==
                        widget.playlist[index]; // ตรวจสอบไฟล์ปัจจุบัน
                    return ListTile(
                      leading: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "Chapter ${index + 1}",
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.orange
                              : Colors.white,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(
                          context,
                        ); // ปิดเมนู
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (
                                  _,
                                ) => PdfViewScreen(
                                  path: widget.playlist[index],
                                  playlist: widget.playlist,
                                ),
                          ),
                        );
                      },
                    );
                  },
            );
          },
    );
  }

  // สร้าง widget สำหรับแสดง PDF ตามโหมดการอ่าน
  Widget
  _buildPdfView() {
    if (_readingMode ==
        ReadingMode.vertical) {
      return PdfViewPinch(
        key: const ValueKey(
          "pinchMode",
        ),
        controller: _pdfControllerPinch!,
        onPageChanged:
            (
              page,
            ) {
              setState(
                () {
                  _currentPage = page; // อัพเดตหน้าปัจจุบัน
                },
              );
            },
      );
    } else {
      return PdfView(
        key: ValueKey(
          _readingMode,
        ),
        controller: _pdfControllerNormal!,
        scrollDirection: Axis.horizontal, // เลื่อนแนวนอน
        reverse:
            _readingMode ==
            ReadingMode.rightToLeft, // ถ้าโหมดขวา→ซ้าย
        onPageChanged:
            (
              page,
            ) {
              setState(
                () {
                  _currentPage = page;
                },
              );
            },
      );
    }
  }

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    final fileName = widget.path
        .split(
          '/',
        )
        .last; // เอาชื่อไฟล์จาก path

    return GestureDetector(
      onTap: () {
        setState(
          () {
            _isUiVisible = !_isUiVisible; // แตะเพื่อซ่อน/โชว์ UI
          },
        );
      },
      child: Scaffold(
        appBar: _isUiVisible
            ? AppBar(
                centerTitle: false,
                iconTheme: const IconThemeData(
                  color: Colors.orange,
                ), // สีปุ่มย้อนกลับ
                backgroundColor: Colors.grey[900], // พื้นหลังมืด
                titleSpacing: 12,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis, // ชื่อยาวตัดด้วย ...
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    // เมนูเลือกโหมดการอ่าน
                    PopupMenuButton<
                      ReadingMode
                    >(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                      tooltip: 'เปลี่ยนโหมดการอ่าน',
                      color: Colors.grey[850],
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
                                _initControllers(); // รีเซ็ต controller เมื่อเปลี่ยนโหมด
                              },
                            );
                          },
                      itemBuilder:
                          (
                            context,
                          ) => [
                            // โหมด scroll ลง
                            PopupMenuItem(
                              value: ReadingMode.vertical,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.swap_vert,
                                    color:
                                        _readingMode ==
                                            ReadingMode.vertical
                                        ? Colors.orange
                                        : Colors.white70,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "โหมดสไลด์ลง (ค่าเริ่มต้น)",
                                      style: TextStyle(
                                        color:
                                            _readingMode ==
                                                ReadingMode.vertical
                                            ? Colors.orange
                                            : Colors.white,
                                        fontWeight:
                                            _readingMode ==
                                                ReadingMode.vertical
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // โหมดเลื่อนขวา → ซ้าย
                            PopupMenuItem(
                              value: ReadingMode.rightToLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_left,
                                    color:
                                        _readingMode ==
                                            ReadingMode.rightToLeft
                                        ? Colors.orange
                                        : Colors.white70,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "โหมดสไลด์ ขวา → ซ้าย",
                                      style: TextStyle(
                                        color:
                                            _readingMode ==
                                                ReadingMode.rightToLeft
                                            ? Colors.orange
                                            : Colors.white,
                                        fontWeight:
                                            _readingMode ==
                                                ReadingMode.rightToLeft
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // โหมดเลื่อนซ้าย → ขวา
                            PopupMenuItem(
                              value: ReadingMode.leftToRight,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_right,
                                    color:
                                        _readingMode ==
                                            ReadingMode.leftToRight
                                        ? Colors.orange
                                        : Colors.white70,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "โหมดสไลด์ ซ้าย → ขวา",
                                      style: TextStyle(
                                        color:
                                            _readingMode ==
                                                ReadingMode.leftToRight
                                            ? Colors.orange
                                            : Colors.white,
                                        fontWeight:
                                            _readingMode ==
                                                ReadingMode.leftToRight
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
              )
            : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: _buildPdfView(),
            ), // แสดง PDF เต็มจอ
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
                        color: Colors.grey[850],
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
                        color: Colors.grey[850],
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
}
