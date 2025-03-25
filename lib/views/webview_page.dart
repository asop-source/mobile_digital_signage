import 'dart:async';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  WebViewPageState createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isValidUrl = true;
  Timer? _refreshTimer; // Timer untuk auto-refresh
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    hideSystemUI();
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
                    print('Page finished: $url');
                  }
                },
                onWebResourceError: (WebResourceError error) {
                  setState(() {
                    _isLoading = false; // Sembunyikan loading indicator
                  });
                  _startAutoRefresh(); // Mulai auto-refresh ketika terjadi error
                  print('Error: ${error.errorCode} - ${error.description}');
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

  void hideSystemUI() async {
    // Untuk Android 10+ (edge-to-edge)
    // 1. Gunakan immersiveSticky untuk menyembunyikan sepenuhnya
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    SystemUiMode.immersiveSticky;
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    // 3. Delay kecil untuk memastikan perubahan diterapkan
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      isFullScreen = true;
      WakelockPlus.toggle(enable: isFullScreen);
    });
  }

  void showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() {
      isFullScreen = false;
      WakelockPlus.toggle(enable: isFullScreen);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Batalkan timer saat widget di-dispose
    WidgetsBinding.instance.removeObserver(this);
    showSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        showSystemUI();
        print(isFullScreen);
        return Future.value(false);
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.transparent),
        child:
            _isValidUrl
                ? Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    Positioned(
                      bottom: 50,
                      right: 0,
                      child: Visibility(
                        visible: !isFullScreen,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isFullScreen) {
                              showSystemUI();
                            } else {
                              hideSystemUI();
                            }
                          },
                          child: Text(isFullScreen ? 'Show System UI' : 'FullScreen'),
                        ),
                      ),
                    ),
                    if (_isLoading) Center(child: CircularProgressIndicator()),
                  ],
                )
                : Center(child: Text('URL tidak valid')),
      ),
    );
  }
}
