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
  List<
    bool
  >
  selectedSeries =
      [];
  bool
  isSelectionMode =
      false;

  // 🎨 สีหลักของธีมเข้ม
  final Color
  _bgColor = const Color(
    0xFF1A1A1A,
  );
  final Color
  _cardColor = const Color(
    0xFF2C2C2C,
  );
  final Color
  _accentColor = const Color(
    0xFFFFA726,
  );

  Future<
    void
  >
  requestPermissions() async {
    if (await Permission.storage.request().isGranted)
      return;
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
            null &&
        result.files.isNotEmpty) {
      List<
        String
      >
      allFiles = [];
      for (var file in result.files) {
        if (file.path !=
            null)
          allFiles.add(
            file.path!,
          );
      }

      if (allFiles.isNotEmpty) {
        String?
        playlistName = await _askPlaylistName();
        if (playlistName !=
                null &&
            playlistName.trim().isNotEmpty) {
          setState(
            () {
              seriesList.add(
                Series(
                  title: playlistName.trim(),
                  files: allFiles,
                ),
              );
              selectedSeries.add(
                false,
              );
            },
          );
        }
      }
    }
  }

  Future<
    String?
  >
  _askPlaylistName() async {
    String
    playlistName =
        "";
    return showDialog<
      String
    >(
      context: context,
      builder:
          (
            context,
          ) {
            return AlertDialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              title: const Text(
                "ตั้งชื่อ Playlist",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              content: TextField(
                style: const TextStyle(
                  color: Colors.white,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "ชื่อ Playlist",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                onChanged:
                    (
                      value,
                    ) => playlistName = value,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                  ),
                  child: Text(
                    "ยกเลิก",
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    playlistName,
                  ),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  Future<
    void
  >
  _editPlaylistName(
    int
    index,
  ) async {
    String
    newName =
        seriesList[index].title;
    final result =
        await showDialog<
          String
        >(
          context: context,
          builder:
              (
                context,
              ) {
                return AlertDialog(
                  backgroundColor: _cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  title: const Text(
                    "แก้ไขชื่อ Playlist",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  content: TextField(
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: "ชื่อ Playlist",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    controller: TextEditingController(
                      text: seriesList[index].title,
                    ),
                    onChanged:
                        (
                          value,
                        ) => newName = value,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                      ),
                      child: Text(
                        "ยกเลิก",
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(
                        context,
                        newName,
                      ),
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (result !=
            null &&
        result.trim().isNotEmpty) {
      setState(
        () {
          seriesList[index].title = result.trim();
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
        width: 300,
        height: 400,
      );
      if (pageImage !=
          null)
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            10,
          ),
          child: Image.memory(
            pageImage.bytes,
            fit: BoxFit.cover,
          ),
        );
    } else if (path.endsWith(
      '.cbz',
    )) {
      final files = await _extractCbzForThumbnail(
        path,
      );
      if (files.isNotEmpty)
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            10,
          ),
          child: Image.file(
            files.first,
            fit: BoxFit.cover,
          ),
        );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
    );
  }

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
    if (!await extractDir
        .exists())
      await extractDir.create(
        recursive: true,
      );

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
        break;
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          isSelectionMode
              ? "${selectedSeries.where((e) => e).length} Selected"
              : "ชั้นหนังสือ",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(
                Icons.edit,
              ),
              color: _accentColor,
              onPressed: () {
                final selectedIndexes =
                    <
                      int
                    >[];
                for (
                  int i = 0;
                  i <
                      selectedSeries.length;
                  i++
                ) {
                  if (selectedSeries[i])
                    selectedIndexes.add(
                      i,
                    );
                }
                if (selectedIndexes.isNotEmpty) {
                  for (final index in selectedIndexes) {
                    _editPlaylistName(
                      index,
                    );
                  }
                }
              },
            ),
          if (isSelectionMode)
            IconButton(
              icon: const Icon(
                Icons.delete,
              ),
              color: Colors.redAccent,
              onPressed: () {
                setState(
                  () {
                    final toRemove =
                        <
                          int
                        >[];
                    for (
                      int i = 0;
                      i <
                          selectedSeries.length;
                      i++
                    ) {
                      if (selectedSeries[i])
                        toRemove.add(
                          i,
                        );
                    }
                    toRemove.sort(
                      (
                        a,
                        b,
                      ) => b.compareTo(
                        a,
                      ),
                    );
                    for (final index in toRemove) {
                      seriesList.removeAt(
                        index,
                      );
                      selectedSeries.removeAt(
                        index,
                      );
                    }
                    isSelectionMode = false;
                  },
                );
              },
            ),
          if (isSelectionMode)
            IconButton(
              icon: const Icon(
                Icons.close,
              ),
              color: Colors.white70,
              onPressed: () {
                setState(
                  () {
                    isSelectionMode = false;
                    selectedSeries = List.filled(
                      seriesList.length,
                      false,
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: seriesList.isEmpty
          ? const Center(
              child: Text(
                "กด + เพื่อเพิ่มไฟล์",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
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
                    final isSelected =
                        selectedSeries.length >
                            index &&
                        selectedSeries[index];

                    return GestureDetector(
                      onLongPress: () {
                        setState(
                          () {
                            isSelectionMode = true;
                            selectedSeries[index] = true;
                          },
                        );
                      },
                      onTap: () {
                        if (isSelectionMode) {
                          setState(
                            () {
                              selectedSeries[index] = !selectedSeries[index];
                            },
                          );
                        } else {
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
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 200,
                        ),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? _accentColor.withOpacity(
                                      0.5,
                                    )
                                  : Colors.black54,
                              blurRadius: isSelected
                                  ? 12
                                  : 6,
                              offset: const Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Expanded(
                                  child:
                                      FutureBuilder<
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
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[800],
                                                  borderRadius: BorderRadius.circular(
                                                    10,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    color: Colors.orangeAccent,
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  series.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelectionMode)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: _accentColor,
                                  onChanged:
                                      (
                                        value,
                                      ) {
                                        setState(
                                          () {
                                            selectedSeries[index] = value!;
                                          },
                                        );
                                      },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: _cardColor,
            context: context,
            builder:
                (
                  BuildContext context,
                ) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.insert_drive_file,
                            color: _accentColor,
                          ),
                          title: const Text(
                            "เพิ่มไฟล์",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(
                              context,
                            );
                            pickFiles();
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
          color: Colors.black,
        ),
      ),
    );
  }
}

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
    if (!await extractDir
        .exists())
      await extractDir.create(
        recursive: true,
      );

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
          );
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
          null)
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            8,
          ),
          child: Image.memory(
            pageImage.bytes,
            fit: BoxFit.cover,
          ),
        );
    } else if (path.endsWith(
      '.cbz',
    )) {
      final files = await extractCbz(
        path,
      );
      if (files.isNotEmpty)
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            8,
          ),
          child: Image.file(
            files.first,
            fit: BoxFit.cover,
          ),
        );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(
          8,
        ),
      ),
    );
  }

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    final Color
    _accentColor = const Color(
      0xFFFFA726,
    );
    final Color
    _bgColor = const Color(
      0xFF1A1A1A,
    );

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(
          color: Colors.orange, // 🎨 สีปุ่มย้อนกลับ
        ),
        title: Text(
          widget.series.title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: widget.series.files.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีไฟล์ในซีรีส์นี้",
                style: TextStyle(
                  color: Colors.grey,
                ),
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
                    return Card(
                      color: const Color(
                        0xFF2C2C2C,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: ListTile(
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
                                      child: CircularProgressIndicator(
                                        color: Colors.orangeAccent,
                                      ),
                                    );
                                  },
                            ),
                        title: Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(
                              () {
                                widget.series.files.removeAt(
                                  index,
                                );
                              },
                            );
                          },
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
                                      playlist: widget.series.files,
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
                                      series: widget.series,
                                      currentIndex: index,
                                      images: images,
                                    ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addFilesToPlaylist,
        backgroundColor: _accentColor,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
