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

  // Palette disamakan dengan halaman login CMS & icon aplikasi (teal)
  static const Color deepTeal = Color(0xFF115E59);
  static const Color midTeal = Color(0xFF0F766E);
  static const Color softTeal = Color(0xFF14B8A6);

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
    ipServerController.dispose();
    cmsKeyController.dispose();
    displayNameController.dispose();
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

    if (ipServer != null &&
        cmsKey != null &&
        displayName != null &&
        urlDevice != null) {
      setState(() {
        isLoadingWidget = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WebViewPage(url: urlDevice)),
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
      // Ambil IPv4 saja: alamat IPv6 terlalu panjang untuk ditampilkan dan
      // berganti-ganti (privacy address), padahal nilai ini dipakai server
      // sebagai kunci unik device.
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) {
            setState(() {
              macAddress = address.address;
            });
            return;
          }
        }
      }
      setState(() {
        macAddress = "IP tidak ditemukan";
      });
    } catch (e) {
      setState(() {
        macAddress = "Gagal mengambil IP";
      });
    }
  }

  Future<void> sendDataToApi() async {
    if (isLoadingApi) return;
    setState(() {
      isLoadingApi = true;
    });

    if (ipServerController.text.isEmpty ||
        cmsKeyController.text.isEmpty ||
        displayNameController.text.isEmpty) {
      if (mounted) {
        Helper.showErrorDialog(context, "Harap periksa konfigurasi");
      }
      setState(() {
        isLoadingApi = false;
      });
      return;
    }

    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!ipRegex.hasMatch(ipServerController.text)) {
      if (mounted) {
        Helper.showErrorDialog(context, "Format IP server tidak valid");
      }
      setState(() {
        isLoadingApi = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://${ipServerController.text}/api/devices/connect"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'ip_server': ipServerController.text,
          'cms_key': cmsKeyController.text,
          'display_name': displayNameController.text,
          'mac_address': macAddress,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          await MySharedPref.setIpServer(ipServerController.text);
          await MySharedPref.setCmsKey(cmsKeyController.text);
          await MySharedPref.setDisplayName(displayNameController.text);
          await MySharedPref.setUrlDevice(responseData['url']);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perangkat berhasil terhubung')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebViewPage(url: responseData['url']),
              ),
            );
          }
        } else {
          if (mounted) {
            Helper.showErrorDialog(
              context,
              "Gagal terhubung: ${responseData['message'] ?? 'Tidak ada pesan error'}",
            );
          }
        }
      } else {
        if (mounted) {
          Helper.showErrorDialog(
            context,
            "Gagal terhubung: Status Code ${response.statusCode}",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helper.showErrorDialog(context, "Terjadi kesalahan: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingApi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepTeal, midTeal, softTeal],
          ),
        ),
        child: SafeArea(
          child:
              isLoadingWidget
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final isSmall = constraints.maxWidth < 400;
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(48),
                                  child: _buildBranding(compact: false),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(48),
                                  child: _buildFormCard(),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 16 : 24,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBranding(compact: true, small: isSmall),
                              const SizedBox(height: 28),
                              _buildFormCard(small: isSmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _buildBranding({required bool compact, bool small = false}) {
    final double iconBox = small ? 56 : 72;
    final double iconSize = small ? 30 : 38;
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(small ? 16 : 20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(Icons.connected_tv, color: Colors.white, size: iconSize),
        ),
        SizedBox(height: small ? 18 : 24),
        Text(
          'Digital Signage',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 26 : 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Hubungkan perangkat ini ke server CMS\nuntuk mulai menayangkan konten.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: small ? 13.5 : 15,
            height: 1.6,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 36),
          _featureRow(Icons.grid_view_rounded, 'Layout & playlist fleksibel'),
          const SizedBox(height: 14),
          _featureRow(Icons.schedule_rounded, 'Penjadwalan tayang otomatis'),
          const SizedBox(height: 14),
          _featureRow(Icons.wifi_tethering_rounded, 'Update konten real-time'),
        ],
      ],
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({bool small = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: EdgeInsets.all(small ? 22 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hubungkan Perangkat',
            style: TextStyle(
              fontSize: small ? 19 : 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2947),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Isi data koneksi sesuai pengaturan di CMS.',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF8A92A6)),
          ),
          const SizedBox(height: 28),
          _buildField(
            controller: ipServerController,
            label: 'IP Server',
            hint: 'Contoh: 43.157.206.193',
            icon: Icons.dns_rounded,
          ),
          const SizedBox(height: 18),
          _buildField(
            controller: cmsKeyController,
            label: 'CMS Key',
            hint: 'Kunci dari menu Settings CMS',
            icon: Icons.vpn_key_rounded,
          ),
          const SizedBox(height: 18),
          _buildField(
            controller: displayNameController,
            label: 'Nama Display',
            hint: 'Contoh: TV Lobby Lantai 1',
            icon: Icons.tv_rounded,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(Icons.lan_rounded, size: 17, color: softTeal),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'IP perangkat ini: $macAddress',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF576078),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [softTeal, midTeal]),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: midTeal.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed:
                    isLoadingApi
                        ? null
                        : () {
                          FocusScope.of(context).unfocus();
                          sendDataToApi();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child:
                    isLoadingApi
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'HUBUNGKAN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF576078),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2947)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAB0C0),
              fontSize: 13.5,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFA2A8BA), size: 20),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE6E9F2),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: softTeal, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
