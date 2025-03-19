import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  Timer? _refreshTimer; // Timer untuk auto-refresh

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
                    _stopAutoRefresh(); // Hentikan auto-refresh setelah halaman berhasil dimuat
                  }
                },
                onWebResourceError: (WebResourceError error) {
                  setState(() {
                    _isLoading = false; // Sembunyikan loading indicator
                  });
                  _startAutoRefresh(); // Mulai auto-refresh ketika terjadi error
                },
              ),
            )
            ..loadRequest(Uri.parse(widget.url));
    } else {
      _isValidUrl = false;
    }
  }

  void _startAutoRefresh() {
    // Jadwalkan refresh setiap 5 detik
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_isLoading == false) {
        // Hanya refresh jika tidak sedang loading
        _controller.reload(); // Refresh halaman
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel(); // Hentikan timer
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Batalkan timer saat widget di-dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Nonaktifkan navigasi kembali default
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Preview Device'),
        //   centerTitle: true,
        //   leading: IconButton(
        //     icon: Icon(Icons.logout, color: Colors.red),
        //     onPressed: () {
        //       Navigator.pop(context);
        //     },
        //   ),
        //   actions: [
        //     IconButton(
        //       icon: Icon(Icons.refresh),
        //       onPressed: () {
        //         _controller.reload();
        //       },
        //     ),
        //   ],
        // ),
        body:
            _isValidUrl
                ? SafeArea(
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading) Center(child: CircularProgressIndicator()),
                    ],
                  ),
                )
                : Center(child: Text('URL tidak valid')),
      ),
    );
  }
}
