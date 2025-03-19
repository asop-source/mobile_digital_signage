import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signage/config/shared_preferences_helper.dart';

import '../helper/helper.dart';
import 'webview_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController ipServerController = TextEditingController();
  final TextEditingController cmsKeyController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  String macAddress = "Mengambil IP...";
  Timer? _timer;
  bool isLoadingWidget = true;
  bool isLoadingApi = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoadingWidget = true;
    });
    getMacAddress();
    checkSharedPreferencesData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void checkSharedPreferencesData() async {
    final ipServer = MySharedPref.getIpServer();
    final cmsKey = MySharedPref.getCmsKey();
    final displayName = MySharedPref.getDisplayName();
    final urlDevice = MySharedPref.getUrlDevice();

    ipServerController.text = ipServer ?? "";
    cmsKeyController.text = cmsKey ?? "";
    displayNameController.text = displayName ?? "";

    if (ipServer != null && cmsKey != null && displayName != null && urlDevice != null) {
      setState(() {
        isLoadingWidget = false;
      });

      // Gunakan addPostFrameCallback untuk navigasi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(url: urlDevice), // Arahkan ke WebViewPage
          ),
        );
      });
    } else {
      setState(() {
        isLoadingWidget = false;
      });
    }
  }

  Future<void> getMacAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      if (interfaces.isNotEmpty) {
        setState(() {
          macAddress = interfaces.first.addresses.first.address;
        });
      }
    } catch (e) {
      setState(() {
        macAddress = "Gagal mengambil IP";
      });
    }
  }

  Future<void> checkInternetConnection() async {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          if (mounted) {
            Helper.showErrorDialog(context, "Koneksi internet terputus");
          }
          return;
        }
      } on SocketException catch (_) {
        if (mounted) {
          Helper.showErrorDialog(context, "Koneksi internet terputus");
        }
        return;
      }
    });
  }

  Future<void> sendDataToApi() async {
    // Flag untuk menghindari double trigger

    // Cek apakah proses sedang berjalan
    if (isLoadingApi) return;
    isLoadingApi = true;

    // Validasi input
    if (ipServerController.text.isEmpty ||
        cmsKeyController.text.isEmpty ||
        displayNameController.text.isEmpty) {
      if (mounted) {
        Helper.showErrorDialog(context, "Harap periksa konfigurasi");
      }
      isLoadingApi = false; // Reset flag
      return;
    }

    // Validasi format IP address (opsional)
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!ipRegex.hasMatch(ipServerController.text)) {
      if (mounted) {
        Helper.showErrorDialog(context, "Format IP server tidak valid");
      }
      isLoadingApi = false; // Reset flag
      return;
    }

    // Cek koneksi internet
    try {
      await checkInternetConnection();
    } catch (e) {
      if (mounted) {
        Helper.showErrorDialog(context, "Tidak ada koneksi internet");
      }
      isLoadingApi = false; // Reset flag
      return;
    }

    // Kirim data ke API
    try {
      final response = await http.post(
        Uri.parse("http://${ipServerController.text}/api/devices/connect"),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'ip_server': ipServerController.text,
          'cms_key': cmsKeyController.text,
          'display_name': displayNameController.text,
          'mac_address': macAddress,
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Simpan data ke shared preferences
          await MySharedPref.setIpServer(ipServerController.text);
          await MySharedPref.setCmsKey(cmsKeyController.text);
          await MySharedPref.setDisplayName(displayNameController.text);
          await MySharedPref.setUrlDevice(responseData['url']);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Berhasil')));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => WebViewPage(url: responseData['url']), // Arahkan ke WebViewPage
              ),
            );
          }
        } else {
          if (mounted) {
            Helper.showErrorDialog(
              context,
              "Login Gagal: ${responseData['message'] ?? 'Tidak ada pesan error'}",
            );
          }
        }
      } else {
        if (mounted) {
          Helper.showErrorDialog(context, "Login Gagal: Status Code ${response.statusCode}");
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        Helper.showErrorDialog(context, "Terjadi kesalahan: ${e.toString()}");
      }
    } finally {
      isLoadingApi = false; // Reset flag setelah proses selesai
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Digital Signage App', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Visibility(
        visible: isLoadingWidget == false,
        child: Container(
          color: Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/images/img.webp', height: 100, width: 100),
                  SizedBox(height: 20),
                  TextField(
                    controller: ipServerController,
                    decoration: InputDecoration(
                      labelText: 'IP Server',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      hintText: 'Contoh: 103.171.84.235',
                      hintStyle: TextStyle(color: Color.fromRGBO(103, 58, 183, 0.6)),
                      filled: true,
                      fillColor: Color.fromRGBO(255, 255, 255, 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.dns, color: Colors.deepPurple),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: cmsKeyController,
                    decoration: InputDecoration(
                      labelText: 'CMS Key',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      hintText: 'Contoh: ThIsIsApPcMSKey',
                      hintStyle: TextStyle(color: Color.fromRGBO(103, 58, 183, 0.6)),
                      filled: true,
                      fillColor: Color.fromRGBO(255, 255, 255, 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.vpn_key, color: Colors.deepPurple),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      hintText: 'Contoh: Kopi Jakarta',
                      hintStyle: TextStyle(color: Color.fromRGBO(103, 58, 183, 0.6)),
                      filled: true,
                      fillColor: Color.fromRGBO(255, 255, 255, 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.business, color: Colors.deepPurple),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'IP Address: $macAddress',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      sendDataToApi();
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder:
                      //         (context) =>
                      //             WebViewPage(url: 'https://www.google.com/search?q=flutter'), // Arahkan ke WebViewPage
                      //   ),
                      // );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      backgroundColor: Colors.deepPurple,
                      shadowColor: Color.fromRGBO(103, 58, 183, 0.5),
                      elevation: 5,
                    ),
                    child: Text('LOGIN', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
