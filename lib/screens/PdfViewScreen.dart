import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

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
  late PdfControllerPinch
  _pdfController;
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
