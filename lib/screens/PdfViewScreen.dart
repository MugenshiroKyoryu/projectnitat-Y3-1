import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewScreen
    extends
        StatefulWidget {
  final String
  path;
  const PdfViewScreen({
    required this.path,
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
  late PdfControllerPinch
  _pdfController;
  int
  _pagesCount =
      0;
  int
  _currentPage =
      1;
  bool
  _isUiVisible =
      true; // ✅ ใช้แทน _showButtons

  @override
  void
  initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(
        widget.path,
      ),
    );
    _loadPdfInfo();
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
    _pdfController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  goToNext() async {
    if (_currentPage <
        _pagesCount) {
      _pdfController.nextPage(
        curve: Curves.ease,
        duration: const Duration(
          milliseconds: 300,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "นี่คือหน้าสุดท้ายแล้ว",
          ),
        ),
      );
    }
  }

  Future<
    void
  >
  goToPrevious() async {
    if (_currentPage >
        1) {
      _pdfController.previousPage(
        curve: Curves.ease,
        duration: const Duration(
          milliseconds: 300,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "นี่คือหน้าแรกแล้ว",
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
              itemCount: _pagesCount,
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
                    final pageNum =
                        index +
                        1;
                    final isCurrent =
                        pageNum ==
                        _currentPage;

                    return ListTile(
                      leading: Text(
                        "$pageNum",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "Page $pageNum",
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
                        _pdfController.jumpToPage(
                          pageNum,
                        );
                      },
                    );
                  },
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
    final fileName = widget.path
        .split(
          '/',
        )
        .last;

    return GestureDetector(
      onTap: () {
        setState(
          () {
            _isUiVisible = !_isUiVisible; // ✅ แตะเพื่อซ่อน/โชว์ UI
          },
        );
      },
      child: Scaffold(
        appBar: _isUiVisible
            ? AppBar(
                title: Text(
                  fileName,
                ),
              )
            : null,
        body: Stack(
          children: [
            PdfViewPinch(
              controller: _pdfController,
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
            ),

            // ✅ ปุ่ม 3 ปุ่มซ้ายล่าง (เหมือน CbzViewScreen)
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
