import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Signage App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ApiExamplePage(),
    );
  }
}

class ApiExamplePage extends StatefulWidget {
  const ApiExamplePage({super.key});

  @override
  ApiExamplePageState createState() => ApiExamplePageState(); // Public class
}

class ApiExamplePageState extends State<ApiExamplePage> {
  final TextEditingController ipServerController = TextEditingController();
  final TextEditingController cmsKeyController = TextEditingController();
  String macAddress = "Mengambil IP...";
  String responseMessage = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    getMacAddress();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      sendDataToApi();
    });
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

  Future<void> sendDataToApi() async {
    final String ipServer = ipServerController.text;
    final String cmsKey = cmsKeyController.text;

    // Validasi input
    if (ipServer.isEmpty || cmsKey.isEmpty) {
      setState(() {
        responseMessage = "IP Server dan CMS Key harus diisi!";
      });
      return;
    }

    // Cek koneksi internet
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        setState(() {
          responseMessage = "Tidak ada koneksi internet!";
        });
        return;
      }
    } on SocketException catch (_) {
      setState(() {
        responseMessage = "Tidak ada koneksi internet!";
      });
      return;
    }

    // Kirim data ke API
    try {
      final response = await http.post(
        Uri.parse("http://$ipServer/api/devices/connect"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'ip_server': ipServer,
          'cms_key': cmsKey,
          'mac_address': macAddress,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          responseMessage = "Data berhasil dikirim: ${response.body}";
        });
      } else {
        setState(() {
          responseMessage = "Gagal mengirim data: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = "Terjadi kesalahan: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Signage App', style: TextStyle(color: Colors.white)),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent.shade100, Colors.blueAccent.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Input IP Server
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

              // Input CMS Key
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
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.vpn_key, color: Colors.deepPurple),
                ),
              ),
              SizedBox(height: 20),

              // Menampilkan MAC Address (IP Address)
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purpleAccent, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    'MAC Address (IP): $macAddress',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Tombol Kirim Data
              ElevatedButton(
                onPressed: sendDataToApi,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.deepPurple,
                  shadowColor: Color.fromRGBO(103, 58, 183, 0.5),
                  elevation: 5,
                ),
                child: Text(
                  'Kirim Data ke API',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),

              // Menampilkan Pesan Respons
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey(responseMessage),
                  responseMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: responseMessage.contains("berhasil") ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}