import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:signage/config/shared_preferences_helper.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as InAppWebView;

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  WebViewPageState createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  WebViewController? _controller;
  InAppWebView.InAppWebViewController? webViewController;
  InAppWebView.InAppWebViewSettings settings =
      InAppWebView.InAppWebViewSettings(
        isInspectable: kDebugMode,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllowFullscreen: true,
      );
  bool _isLoading = true;
  bool _isValidUrl = true;
  // Timer? _refreshTimer; // Timer untuk auto-refresh
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    hideSystemUI();
    print(Uri.tryParse(widget.url)?.hasAbsolutePath);
    if (Uri.tryParse(widget.url)?.hasAbsolutePath ?? false) {
      if (Platform.isWindows) {
        _isLoading = false; // Set loading indicator ke false untuk Windows
        webViewController?.loadUrl(
          urlRequest: InAppWebView.URLRequest(
            url: InAppWebView.WebUri(widget.url),
          ),
        );
        webViewController?.setOptions(
          options: InAppWebView.InAppWebViewGroupOptions(
            crossPlatform: InAppWebView.InAppWebViewOptions(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              useOnDownloadStart: true,
              useOnLoadResource: true,
            ),
          ),
        );
      } else {
        _controller =
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..addJavaScriptChannel(
                'FlutterLogout',
                onMessageReceived: (JavaScriptMessage message) {
                  _handleForcedLogout();
                },
              )
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
                      // _stopAutoRefresh(); // Hentikan auto-refresh setelah halaman berhasil dimuat
                      print('Page finished: $url');
                    }
                  },
                  onWebResourceError: (WebResourceError error) {
                    setState(() {
                      _isLoading = false; // Sembunyikan loading indicator
                    });
                    // _startAutoRefresh(); // Mulai auto-refresh ketika terjadi error
                    print('Error: ${error.errorCode} - ${error.description}');
                  },
                ),
              )
              ..loadRequest(Uri.parse(widget.url));

        // Android WebView requires a user gesture before playing media by
        // default, which silently blocks the <video autoplay> layout items.
        // Disable that requirement, matching the Windows InAppWebView config above.
        if (_controller!.platform is AndroidWebViewController) {
          (_controller!.platform as AndroidWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        }
      }
    } else {
      _isValidUrl = false;
    }
  }

  // void _startAutoRefresh() {
  //   // Jadwalkan refresh setiap 5 detik
  //   _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
  //     if (_isLoading == false) {
  //       // Hanya refresh jika tidak sedang loading
  //       _controller.reload(); // Refresh halaman
  //     }
  //   });
  // }

  // void _stopAutoRefresh() {
  //   _refreshTimer?.cancel(); // Hentikan timer
  // }

  // Dipanggil dari halaman web (via JS channel) saat CMS menolak atau
  // menghapus device ini, supaya app otomatis kembali ke layar registrasi
  // tanpa perlu ditekan manual.
  Future<void> _handleForcedLogout() async {
    await MySharedPref.clear();
    if (mounted) {
      showSystemUI();
      Navigator.pop(context);
    }
  }

  void hideSystemUI() async {
    // Untuk Android 10+ (edge-to-edge)
    // 1. Gunakan immersiveSticky untuk menyembunyikan sepenuhnya
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
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
    // _refreshTimer?.cancel(); // Batalkan timer saat widget di-dispose
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
                    Visibility(
                      visible: Platform.isWindows == false,
                      replacement: InAppWebView.InAppWebView(
                        initialUrlRequest: InAppWebView.URLRequest(
                          url: InAppWebView.WebUri(widget.url),
                        ),
                        initialSettings: settings,
                        onWebViewCreated: (
                          InAppWebView.InAppWebViewController controller,
                        ) {
                          webViewController = controller;
                          controller.addJavaScriptHandler(
                            handlerName: 'FlutterLogout',
                            callback: (args) {
                              _handleForcedLogout();
                            },
                          );
                        },
                      ),
                      child:
                          _controller != null
                              ? WebViewWidget(controller: _controller!)
                              : Center(child: Text('Loading WebView...')),
                    ),
                    Positioned(
                      bottom: 50,
                      right: 0,
                      child: Visibility(
                        visible: !isFullScreen,
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: _handleForcedLogout,
                              child: const Text('Logout'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (isFullScreen) {
                                  showSystemUI();
                                } else {
                                  hideSystemUI();
                                }
                              },
                              child: Text(
                                isFullScreen ? 'Show System UI' : 'FullScreen',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Visibility(
                        visible: Platform.isWindows == false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                )
                : Center(child: Text('URL tidak valid')),
      ),
    );
  }
}
