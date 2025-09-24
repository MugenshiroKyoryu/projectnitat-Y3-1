import 'package:flutter/material.dart';

class ReaderScreen
    extends
        StatelessWidget {
  const ReaderScreen({
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
          'Reader Screen',
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'นี่คือหน้าสำหรับอ่านการ์ตูน',
        ),
      ),
    );
  }
}
