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
  _showButtons =
      false;

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

  void
  _toggleButtons() {
    setState(() {
      _showButtons = !_showButtons;
    });
  }

  @override
  void
  dispose() {
    _pdfController.dispose();
    super.dispose();
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
          "PDF Viewer",
        ),
      ),
      body: GestureDetector(
        onTap: _toggleButtons,
        child: Stack(
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
                        // ถ้าเป็นหน้าสุดท้าย ให้โชว์ปุ่มโดยอัตโนมัติ
                        if (_currentPage ==
                            _pagesCount) {
                          _showButtons = true;
                        }
                      },
                    );
                  },
            ),
            if (_showButtons) // แสดงปุ่มเมื่อ _showButtons = true
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _customButton(
                          "ตอนก่อนหน้า",
                          Icons.arrow_back,
                          () {
                            _pdfController.previousPage(
                              curve: Curves.ease,
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        _customButton(
                          "ตอนต่อไป",
                          Icons.arrow_forward,
                          () {
                            _pdfController.nextPage(
                              curve: Curves.ease,
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget
  _customButton(
    String
    label,
    IconData
    icon,
    VoidCallback
    onTap,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(
          8,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
