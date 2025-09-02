import 'package:flutter/material.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const SearchScreen(),
    );
  }
}
