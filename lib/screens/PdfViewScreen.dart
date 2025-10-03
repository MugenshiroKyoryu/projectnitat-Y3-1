import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

enum ReadingMode {
  vertical, // ค่าเริ่มต้น สไลด์ลง
  leftToRight, // ซ้าย → ขวา
  rightToLeft, // ขวา → ซ้าย
}

class PdfViewScreen
    extends
        StatefulWidget {
  final String
  path;
  final List<
    String
  >
  playlist;

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
  _pdfControllerPinch;
  PdfController?
  _pdfControllerNormal;

  int
      // ignore: unused_field
      _pagesCount =
      0;
  int
      // ignore: unused_field
      _currentPage =
      1;
  bool
  _isUiVisible =
      true;

  ReadingMode
  _readingMode =
      ReadingMode.vertical;

  @override
  void
  initState() {
    super.initState();
    _initControllers();
    _loadPdfInfo();
  }

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
    _pdfControllerPinch?.dispose();
    _pdfControllerNormal?.dispose();
    super.dispose();
  }

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

  void
  showChaptersMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
                        widget.playlist[index];
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
                        );
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
                  _currentPage = page;
                },
              );
            },
      );
    } else {
      return PdfView(
        key: ValueKey(
          _readingMode,
        ), // เปลี่ยน key ทุกครั้งเพื่อสร้างใหม่
        controller: _pdfControllerNormal!,
        scrollDirection: Axis.horizontal,
        reverse:
            _readingMode ==
            ReadingMode.rightToLeft,
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
        .last;

    return GestureDetector(
      onTap: () {
        setState(
          () {
            _isUiVisible = !_isUiVisible;
          },
        );
      },
      child: Scaffold(
        appBar: _isUiVisible
            ? AppBar(
                centerTitle: false,
                titleSpacing: 12,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    PopupMenuButton<
                      ReadingMode
                    >(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                      ),
                      tooltip: 'mode',
                      onSelected:
                          (
                            mode,
                          ) {
                            setState(
                              () {
                                _readingMode = mode;
                                _initControllers(); // สร้าง controller ใหม่ทุกครั้งที่เปลี่ยนโหมด
                              },
                            );
                          },
                      itemBuilder:
                          (
                            context,
                          ) => [
                            const PopupMenuItem(
                              value: ReadingMode.vertical,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.swap_vert,
                                  ), // เลือกไอคอนที่ต้องการ
                                  SizedBox(
                                    width: 8,
                                  ), // เว้นช่องว่างระหว่างไอคอนกับข้อความ
                                  Text(
                                    "โหมดสไลด์ลง (ค่าเริ่มต้น)",
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ReadingMode.rightToLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_left,
                                  ), // เลือกไอคอนที่ต้องการ
                                  SizedBox(
                                    width: 8,
                                  ), // เว้นช่องว่างระหว่างไอคอนกับข้อความ
                                  Text(
                                    "โหมดสไลด์ ขวา → ซ้าย",
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ReadingMode.leftToRight,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_right,
                                  ), // เลือกไอคอนที่ต้องการ
                                  SizedBox(
                                    width: 8,
                                  ), // เว้นช่องว่างระหว่างไอคอนกับข้อความ
                                  Text(
                                    "โหมดสไลด์ ซ้าย → ขวา",
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
            ),
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
