import 'dart:io';
import 'package:flutter/material.dart';

class CbzViewScreen
    extends
        StatelessWidget {
  final List<
    File
  >
  images;
  const CbzViewScreen({
    required this.images,
    super.key,
  });

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CBZ Viewer",
        ),
      ),
      body: ListView.builder(
        itemCount: images.length,
        itemBuilder:
            (
              context,
              index,
            ) {
              return Image.file(
                images[index],
              );
            },
      ),
    );
  }
}
