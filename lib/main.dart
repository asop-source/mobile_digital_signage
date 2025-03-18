import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart'; // Import paket webview_flutter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Signage App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ApiExamplePage(),
    );
  }
}

class ApiExamplePage extends StatefulWidget {
  const ApiExamplePage({super.key});

  @override
  ApiExamplePageState createState() => ApiExamplePageState();
}

class ApiExamplePageState extends State<ApiExamplePage> {
  final TextEditingController ipServerController = TextEditingController();
  final TextEditingController cmsKeyController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  String macAddress = "Mengambil IP...";
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
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
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
    final String displayName = displayNameController.text;

    // Validasi input
    if (ipServer.isEmpty || cmsKey.isEmpty || displayName.isEmpty) {
      if (mounted) {
        _showErrorDialog(context, "Harap periksa konfigurasi");
      }
      return;
    }

    // Cek koneksi internet
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        if (mounted) {
          _showErrorDialog(context, "Koneksi internet terputus");
        }
        return;
      }
    } on SocketException catch (_) {
      if (mounted) {
        _showErrorDialog(context, "Koneksi internet terputus");
      }
      return;
    }

    // Kirim data ke API
    try {
      final response = await http.post(
        Uri.parse("http://$ipServer/api/devices/connect"),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'ip_server': ipServer,
          'cms_key': cmsKey,
          'display_name': displayName,
          'mac_address': macAddress,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          if (mounted) {
            _showSuccessDialog(context, "Login Berhasil", () {
              print(responseData['url']);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WebViewPage(url: responseData['url']), // Arahkan ke WebViewPage
                ),
              );
            });
          }
        } else {
          if (mounted) {
            _showErrorDialog(context, "Login Gagal");
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(context, "Login Gagal");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, "Koneksi internet terputus");
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String message, VoidCallback onPressed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sukses"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                onPressed();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      body: Container(
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
                  onPressed: sendDataToApi,
                  // onPressed: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder:
                  //           (context) =>
                  //               WebViewPage(url: 'https://google.com'), // Arahkan ke WebViewPage
                  //     ),
                  //   );
                  // },
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
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  WebViewPageState createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isValidUrl = true;

  @override
  void initState() {
    super.initState();
    print(Uri.tryParse(widget.url)?.hasAbsolutePath);
    if (Uri.tryParse(widget.url)?.hasAbsolutePath ?? false) {
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                    });
                  }
                },
                onPageFinished: (String url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                onWebResourceError: (WebResourceError error) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
            )
            ..loadRequest(Uri.parse(widget.url));
    } else {
      _isValidUrl = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Nonaktifkan navigasi kembali default
      child: Scaffold(
        appBar: AppBar(title: const Text('Preview Device')),
        body:
            _isValidUrl
                ? Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading) Center(child: CircularProgressIndicator()),
                  ],
                )
                : Center(child: Text('URL tidak valid')),
      ),
    );
  }
}
