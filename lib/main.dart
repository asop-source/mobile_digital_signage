import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

import 'config/permission_handler.dart';
import 'config/shared_preferences_helper.dart';
import 'views/home_page.dart'; // Import paket webview_flutter

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionHandler().init();
  await MySharedPref.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Signage App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
