import 'dart:io'; //ใช้ ทำงานกับไฟล์และระบบของเครื่อง
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; //ใช้สำหรับ เปิดหน้าต่างเลือกไฟล์
import 'package:path_provider/path_provider.dart'; //ใช้เพื่อ หาที่เก็บไฟล์ภายในเครื่อง
import 'package:archive/archive_io.dart'; //ใช้สำหรับ บีบอัด/คลายบีบอัดไฟล์ (ZIP, CBZ, RAR ฯลฯ)โดยเฉพาะ CBZ ซึ่งก็คือ ZIP ของรูปภาพ
import 'package:pdfx/pdfx.dart'; //ใช้สำหรับ เปิดและแสดงไฟล์ PDF
import 'package:permission_handler/permission_handler.dart'; //ใช้สำหรับ ขอสิทธิ์ (Permission) จากระบบ เช่น สิทธิ์เข้าถึงไฟล์, กล้อง, หรือที่เก็บข้อมูล

import 'PdfViewScreen.dart';
import 'CbzViewScreen.dart';
import 'package:workshopfinal/models/data.dart';

//-----------------------------------หน้าหลัก-----------------------------------//

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

  //-----------------------------------ฟังก์ชันสำหรับขอสิทธิ์เข้าถึงไฟล์-----------------------------------//
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

  //-----------------------------------ให้ผู้ใช้เลือกไฟล์ PDF หรือ CBZ หลายไฟล์ แล้วบันทึกเป็นเพลย์ลิสต์ใหม่ (Series)-----------------------------------//

  Future<
    void
  >
  pickFiles() async {
    await requestPermissions();
    FilePickerResult?
    result = await FilePicker.platform.pickFiles(
      allowMultiple: true, //เลือกได้หลายไฟล์
      type: FileType.custom, //จำกัดประเภทไฟล์เอง
      allowedExtensions: [
        'pdf',
        'cbz',
      ], //เลือกได้เฉพาะไฟล์ PDF และ CBZ
      allowCompression: false, //ไม่บีบไฟล์
      withData: false, //เอาเฉพาะ path ของไฟล์ ไม่ต้องโหลดข้อมูลไฟล์เข้าหน่วยความจำ
    );

    if (result !=
            null &&
        result.files.isNotEmpty) /*ตรวจสอบว่าผู้ใช้เลือกไฟล์จริง (ไม่กดยกเลิก)*/ {
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
      } /*สร้างลิสต์ allFiles วนลูปเพิ่ม path ของแต่ละไฟล์ที่เลือกเข้ามาในลิสต์*/

      if (allFiles.isNotEmpty) {
        String?
        playlistName = await _askPlaylistName(); /*ถ้ามีไฟล์จริง → เรียก _askPlaylistName()เพื่อให้ผู้ใช้ตั้งชื่อ “เพลย์ลิสต์” (หรือชุดหนังสือ/การ์ตูน)*/
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
              ); /*ถ้าผู้ใช้ตั้งชื่อเพลย์ลิสต์แล้ว (ไม่ว่าง ไม่ยกเลิก)→ ใช้ setState() เพื่ออัปเดตหน้า UI (เช่น "Series(title: 'One Piece', files: ['1.pdf', '2.pdf', ...])") selectedSeries.add(false) อาจใช้เพื่อเก็บสถานะ “เลือก/ไม่เลือก” ของแต่ละเพลย์ลิสต์*/
            },
          );
        }
      }
    }
  }

  //-----------------------------------ให้ผู้ใช้พิมพ์ชื่อ Playlist (สร้างใหม่ หรือแก้ไขของเดิม)-----------------------------------//

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

  //-----------------------------------สร้างภาพตัวอย่าง (thumbnail) ของไฟล์ — ซึ่งอาจเป็น PDF หรือ CBZ (ไฟล์การ์ตูน)-----------------------------------//

  Future<
    Widget
  >
  buildThumbnail(
    String
    path, //อ่านไฟล์จาก path
  ) async {
    if (path.endsWith(
      '.pdf', //ถ้าเป็น .pdf → แสดงภาพจากหน้าแรกของ PDF
    )) {
      final doc = await PdfDocument.openFile(
        path, //เปิดไฟล์ PDF จาก path
      );
      final page = await doc.getPage(
        1, //เปิดหน้าแรกของ PDF
      );
      final pageImage = await page.render(
        width: 300,
        height: 400,
      ); //แปลงหน้า PDF เป็นรูปภาพ
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
      '.cbz', //ถ้าเป็น .cbz → แสดงภาพแรกจากไฟล์การ์ตูน
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
          ), //ถ้า render สำเร็จ → นำรูปมาแสดงด้วย Image.memory() (เพราะรูปอยู่ในหน่วยความจำเป็น bytes)
        );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
    ); //ถ้าไม่ใช่ PDF หรือ CBZ (หรือเปิดไม่ได้) แสดงกล่องเปล่าสีเทาเข้มแทน เพื่อให้ layout ไม่พังและดูเรียบร้อย
  }

  //-----------------------------------แตกไฟล์ .cbz)-----------------------------------//

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
    ).readAsBytes(); //อ่านไฟล์ .cbz ทั้งหมดจากพาธที่ให้มา ผลลัพธ์เป็นข้อมูลดิบ (raw bytes) ของไฟล์ ZIP
    final archive = ZipDecoder().decodeBytes(
      bytes,
    ); //ใช้แพ็กเกจ archive เพื่อถอดรหัส ZIP (CBZ) และdecodeBytes() จะอ่าน bytes แล้วแปลงเป็นอ็อบเจ็กต์ Archive ที่ข้างในมีไฟล์ทั้งหมดใน .cbz (เช่น .jpg, .png, .xml ฯลฯ
    final tempDir =
        await getTemporaryDirectory(); //ดึงโฟลเดอร์ชั่วคราวของแอป (ที่ Flutter จัดให้)🔹 ใช้เพื่อเก็บไฟล์ที่แตกออกมา
    final cbzName = cbzPath
        .split(
          '/',
        )
        .last
        .replaceAll(
          '.cbz',
          '',
        ); //ตัดชื่อไฟล์ออกมาจากพาธ เช่น/storage/emulated/0/Comics/Naruto.cbz → Naruto
    final extractDir = Directory(
      '${tempDir.path}/$cbzName-thumb',
    ); //กำหนดโฟลเดอร์ที่จะเก็บไฟล์แตกไว้เช่น /cache/Naruto-thumb
    if (!await extractDir
        .exists())
      await extractDir.create(
        recursive: true,
      ); //ตรวจว่ามีโฟลเดอร์นี้อยู่หรือยัง🔹 ถ้ายังไม่มี → สร้างใหม่ (รวมถึงโฟลเดอร์ย่อย ๆ ด้วย เพราะ recursive: true)

    List<
      File
    >
    imageFiles =
        []; //สร้างลิสต์ว่างไว้เก็บไฟล์ที่แตกออกมา (ในที่นี้จะมีแค่ 1 รูป)
    for (final file
        in archive) /*วนลูปทุกไฟล์ภายใน .cbz (ที่ decode จาก ZIP ไว้ก่อนหน้านี้)*/ {
      if (file.isFile) /*ตรวจว่าไฟล์ใน archive เป็นไฟล์จริง (ไม่ใช่โฟลเดอร์)ถ้าใช่ — ทำงานข้างในต่อ*/ {
        final filename = '${extractDir.path}/${file.name}'; /*สร้าง path สำหรับบันทึกไฟล์ที่จะแตก เช่น📂 /cache/Naruto-thumb/page01.jpg*/
        final outFile = File(
          filename,
        ); //สร้างไฟล์ใหม่ตาม path ที่กำหนด
        await outFile.create(
          recursive: true,
        ); //recursive: true ช่วยให้สร้างโฟลเดอร์ย่อยอัตโนมัติหากยังไม่มี
        await outFile.writeAsBytes(
          file.content
              as List<
                int
              >,
        ); //เขียนข้อมูลในไฟล์ (ที่อยู่ใน file.content) ออกมาเป็นไฟล์จริงบนเครื่อง ใช้ as List<int> เพราะเนื้อหาไฟล์ ZIP เก็บเป็น bytes
        imageFiles.add(
          outFile,
        ); //เพิ่มไฟล์ที่สร้างเสร็จลงในลิสต์ imageFiles
        break; //ออกจากลูปทันทีหลังจากเจอไฟล์แรก
      }
    }
    return imageFiles; //ส่งกลับลิสต์ที่มีไฟล์ภาพ 1 ไฟล์ (ภาพแรกใน .cbz)
  }

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    return Scaffold(
      backgroundColor: _bgColor, // กำหนดสีพื้นหลังของหน้าจอ
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // สีพื้นหลัง AppBar
        title: Text(
          isSelectionMode
              ? "${selectedSeries.where((e) => e).length} Selected" // ถ้าอยู่โหมดเลือก แสดงจำนวนไอเท็มที่เลือก
              : "ชั้นหนังสือ", // ปกติแสดงชื่อหน้าปกติ
          style: const TextStyle(
            color: Colors.white, // สีตัวอักษร
            fontWeight: FontWeight.bold, // ตัวอักษรหนา
          ),
        ),
        actions: [
          if (isSelectionMode) // ถ้าอยู่โหมดเลือก
            IconButton(
              icon: const Icon(
                Icons.edit, // ไอคอนแก้ไข
              ),
              color: _accentColor, // สีไอคอน
              onPressed: () {
                final selectedIndexes =
                    <
                      int
                    >[]; // สร้าง List เก็บ index ของไอเท็มที่เลือก
                for (
                  int i = 0;
                  i <
                      selectedSeries.length;
                  i++
                ) {
                  if (selectedSeries[i])
                    selectedIndexes.add(
                      i,
                    ); // เก็บ index ของไอเท็มที่ถูกเลือก
                }
                if (selectedIndexes.isNotEmpty) {
                  for (final index in selectedIndexes) {
                    _editPlaylistName(
                      index,
                    ); // เรียกฟังก์ชันแก้ไขชื่อ Playlist ตาม index
                  }
                }
              },
            ),
          if (isSelectionMode) // ถ้าอยู่โหมดเลือก
            IconButton(
              icon: const Icon(
                Icons.delete, // ไอคอนลบ
              ),
              color: Colors.redAccent, // สีไอคอนแดง
              onPressed: () {
                setState(
                  () {
                    final toRemove =
                        <
                          int
                        >[]; // สร้าง List เก็บ index ของไอเท็มที่จะลบ
                    for (
                      int i = 0;
                      i <
                          selectedSeries.length;
                      i++
                    ) {
                      if (selectedSeries[i])
                        toRemove.add(
                          i,
                        ); // เก็บ index ของไอเท็มที่เลือก
                    }
                    toRemove.sort(
                      (
                        a,
                        b,
                      ) => b.compareTo(
                        a,
                      ),
                    ); // จัดเรียงจากมากไปน้อยเพื่อไม่ให้ remove ผิดตำแหน่ง
                    for (final index in toRemove) {
                      seriesList.removeAt(
                        index,
                      ); // ลบไอเท็มออกจาก seriesList
                      selectedSeries.removeAt(
                        index,
                      ); // ลบสถานะเลือกออกจาก selectedSeries
                    }
                    isSelectionMode = false; // ออกจากโหมดเลือกหลังลบเสร็จ
                  },
                );
              },
            ),
        ],
      ),

      body: seriesList.isEmpty
          // ถ้าไม่มีข้อมูลใน seriesList ให้แสดงข้อความกึ่งกลางหน้าจอ
          ? const Center(
              child: Text(
                "กด + เพื่อเพิ่มไฟล์", // ข้อความบอกผู้ใช้ให้เพิ่มไฟล์
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            )
          // ถ้ามีข้อมูลใน seriesList ให้สร้าง GridView แสดงรายการ
          : GridView.builder(
              padding: const EdgeInsets.all(
                8,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // จำนวนคอลัมน์
                childAspectRatio: 0.7, // อัตราส่วนของความสูง/ความกว้างของแต่ละช่อง
                crossAxisSpacing: 8, // ระยะห่างระหว่างคอลัมน์
                mainAxisSpacing: 8, // ระยะห่างระหว่างแถว
              ),
              itemCount: seriesList.length, // จำนวนไอเท็มใน Grid
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final series = seriesList[index]; // ข้อมูลแต่ละ series
                    final isSelected =
                        selectedSeries.length >
                            index &&
                        selectedSeries[index];
                    // ตรวจสอบว่าไอเท็มนี้ถูกเลือกอยู่หรือไม่

                    return GestureDetector(
                      onLongPress: () {
                        // กดค้างเพื่อเปิดโหมดเลือกหลายไอเท็ม
                        setState(
                          () {
                            isSelectionMode = true;
                            selectedSeries[index] = true; // เลือกไอเท็มนี้
                          },
                        );
                      },
                      onTap: () {
                        if (isSelectionMode) {
                          // ถ้าอยู่ในโหมดเลือกหลายไอเท็ม ให้สลับสถานะเลือก
                          setState(
                            () {
                              selectedSeries[index] = !selectedSeries[index];
                            },
                          );
                        } else {
                          // ถ้าไม่ได้อยู่ในโหมดเลือกหลายไอเท็ม เปิดหน้ารายละเอียด series
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
                          color: _cardColor, // สีพื้นหลังการ์ด
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // มุมโค้ง
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? _accentColor.withOpacity(
                                      0.5,
                                    ) // เงาไฮไลต์ถ้าเลือก
                                  : Colors.black54, // เงาปกติ
                              blurRadius: isSelected
                                  ? 12
                                  : 6, // ความฟุ้งของเงา
                              offset: const Offset(
                                0,
                                4,
                              ), // การเลื่อนเงา
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
                                        // สร้าง thumbnail ของไฟล์แรกใน series
                                        builder:
                                            (
                                              context,
                                              snapshot,
                                            ) {
                                              if (snapshot.hasData) return snapshot.data!;
                                              // ถ้ายังโหลดไม่เสร็จ แสดงวงล้อโหลด
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
                                  series.title, // แสดงชื่อ series
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
                              // ถ้าอยู่ในโหมดเลือกหลายไอเท็ม ให้แสดง Checkbox มุมขวาบน
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
          // กดปุ่ม + เพื่อเพิ่มไฟล์
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
                            ); // ปิด bottom sheet
                            pickFiles(); // เรียกฟังก์ชันเลือกไฟล์
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
  series; // รับข้อมูล Series ที่จะแสดงรายละเอียด
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
  // ฟังก์ชันสำหรับแตกไฟล์ .cbz ออกมาเป็นรูปภาพ
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
    ).readAsBytes(); // อ่านไฟล์ .cbz เป็น byte
    final archive = ZipDecoder().decodeBytes(
      bytes,
    ); // แตก zip
    final tempDir =
        await getTemporaryDirectory(); // โฟลเดอร์ชั่วคราวสำหรับเก็บไฟล์

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
    ); // สร้างโฟลเดอร์เก็บรูป
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
        ); // เขียนไฟล์รูปลงเครื่อง
        imageFiles.add(
          outFile,
        ); // เก็บไฟล์รูปลง list
      }
    }
    return imageFiles; // คืนค่า list รูปทั้งหมด
  }

  // ฟังก์ชันสำหรับเพิ่มไฟล์ PDF/CBZ เข้า Series
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
      ], // จำกัดเฉพาะ PDF/CBZ
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
          ); // เก็บ path ของไฟล์ที่เลือก
      }
      setState(
        () {
          widget.series.files.addAll(
            newFiles,
          ); // เพิ่มไฟล์ใหม่เข้า Series
        },
      );
    }
  }

  // ฟังก์ชันสร้าง thumbnail ของไฟล์ PDF หรือ CBZ
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
      ); // เปิด PDF
      final page = await doc.getPage(
        1,
      ); // เลือกหน้าแรก
      final pageImage = await page.render(
        width: 120,
        height: 160,
      ); // สร้าง image
      if (pageImage !=
          null)
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            8,
          ),
          child: Image.memory(
            pageImage.bytes, // แสดง thumbnail จาก memory
            fit: BoxFit.cover,
          ),
        );
    } else if (path.endsWith(
      '.cbz',
    )) {
      final files = await extractCbz(
        path,
      ); // แตก CBZ ออกมา
      if (files.isNotEmpty)
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            8,
          ),
          child: Image.file(
            files.first, // ใช้รูปแรกของ CBZ เป็น thumbnail
            fit: BoxFit.cover,
          ),
        );
    }
    // ถ้าไม่ใช่ PDF หรือ CBZ ให้แสดง placeholder
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
    // กำหนดสีหลักของ UI
    final Color
    _accentColor = const Color(
      0xFFFFA726,
    ); // สีปุ่ม / ไฮไลต์
    final Color
    _bgColor = const Color(
      0xFF1A1A1A,
    ); // สีพื้นหลังของหน้าจอ

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // สีพื้นหลัง AppBar
        iconTheme: const IconThemeData(
          color: Colors.orange, // 🎨 สีไอคอนย้อนกลับ
        ),
        title: Text(
          widget.series.title, // แสดงชื่อซีรีส์ใน AppBar
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      // แสดงเนื้อหาในหน้าจอ
      body: widget.series.files.isEmpty
          // ถ้าไม่มีไฟล์ในซีรีส์ ให้แสดงข้อความกลางหน้าจอ
          ? const Center(
              child: Text(
                "ไม่มีไฟล์ในซีรีส์นี้",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
          // ถ้ามีไฟล์ ให้สร้าง ListView แสดงรายการไฟล์
          : ListView.builder(
              itemCount: widget.series.files.length, // จำนวนไฟล์ในซีรีส์
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final path = widget.series.files[index]; // path ของไฟล์
                    final fileName = path
                        .split(
                          '/',
                        )
                        .last; // ชื่อไฟล์

                    return Card(
                      color: const Color(
                        0xFF2C2C2C,
                      ), // สีพื้นหลังของ card
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // มุมโค้ง
                      ),
                      child: ListTile(
                        // แสดง thumbnail ของไฟล์ PDF หรือ CBZ
                        leading:
                            FutureBuilder<
                              Widget
                            >(
                              future: buildThumbnail(
                                path,
                              ), // เรียกฟังก์ชันสร้าง thumbnail
                              builder:
                                  (
                                    context,
                                    snapshot,
                                  ) {
                                    if (snapshot.hasData) return snapshot.data!; // ถ้าโหลดเสร็จ
                                    return const SizedBox(
                                      width: 50,
                                      child: CircularProgressIndicator(
                                        color: Colors.orangeAccent, // แสดงวงล้อโหลด
                                      ),
                                    );
                                  },
                            ),
                        title: Text(
                          fileName, // แสดงชื่อไฟล์
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        // ปุ่มลบไฟล์
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
                                ); // ลบไฟล์ออกจาก list
                              },
                            );
                          },
                        ),
                        // กดที่ไฟล์เพื่อเปิด
                        onTap: () async {
                          if (path.endsWith(
                            '.pdf',
                          )) {
                            // ถ้าเป็น PDF ให้เปิด PdfViewScreen
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
                            // ถ้าเป็น CBZ ให้แตกไฟล์และเปิด CbzViewScreen
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

      // ปุ่มลอย + สำหรับเพิ่มไฟล์เข้า Series
      floatingActionButton: FloatingActionButton(
        onPressed: addFilesToPlaylist, // เรียกฟังก์ชันเพิ่มไฟล์
        backgroundColor: _accentColor,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
