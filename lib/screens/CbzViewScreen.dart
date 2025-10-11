import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:workshopfinal/models/data.dart';

enum ReadingMode {
  vertical, // ค่าเริ่มต้น สไลด์ลง
  leftToRight, // ซ้าย → ขวา
  rightToLeft, // ขวา → ซ้าย
}

class CbzViewScreen
    extends
        StatefulWidget {
  final Series
  series;
  final int
  currentIndex;
  final List<
    File
  >
  images;

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
  bool
  _isUiVisible =
      true;
  ReadingMode
  _readingMode =
      ReadingMode.vertical;

  Key
  _viewKey =
      UniqueKey();
  final PageController
  _pageController =
      PageController();

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
    _pageController.dispose();
    super.dispose();
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
            _viewKey = UniqueKey();
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
            _viewKey = UniqueKey();
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
                              _viewKey = UniqueKey();
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

  Widget
  imageView() {
    switch (_readingMode) {
      case ReadingMode.vertical:
        return Container(
          color: Colors.black, // ✅ ใช้ Container แทน backgroundColor
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

      case ReadingMode.leftToRight:
      case ReadingMode.rightToLeft:
        return PageView.builder(
          key: _viewKey,
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          reverse:
              _readingMode ==
              ReadingMode.rightToLeft,
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
            _isUiVisible = !_isUiVisible;
          },
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
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
                  color: Colors.orange, // 🎨 สีปุ่มย้อนกลับ
                ),
                actions: [
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
                              _viewKey = UniqueKey();
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
                                );
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
