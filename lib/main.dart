import 'package:flutter/material.dart';
import 'package:workshopfinal/screens/้Home_Screen.dart';
import 'package:workshopfinal/screens/reader_screen.dart';
import 'package:workshopfinal/screens/import_screen.dart';

void
main() {
  runApp(
    const MyApp(),
  );
}

class MyApp
    extends
        StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget
  build(
    BuildContext
    context,
  ) {
    return MaterialApp(
      title: 'OPREADERS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: HomeScreen(),

      //Map ของเส้นทาง (route) ที่ Flutter ใช้เวลาเปลี่ยนหน้า
      routes: {
        '/reader':
            (
              _,
            ) => ReaderScreen(),
        '/import':
            (
              _,
            ) => ImportScreen(),
      },
    );
  }
}
