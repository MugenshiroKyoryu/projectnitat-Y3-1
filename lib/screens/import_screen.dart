import 'package:flutter/material.dart';

class ImportScreen
    extends
        StatelessWidget {
  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Import",
        ),
      ),
      body: Center(
        child: Text(
          "นี่คือหน้าสำหรับ import ไฟล์",
        ),
      ),
    );
  }
}
