import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  init() async {
    await requestLocationPermission();
  }

  /// Method umum untuk meminta izin dan menangani error
  Future<bool> _requestPermission(Permission permission, String permissionName) async {
    try {
      PermissionStatus status = await permission.status;

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        status = await permission.request();
        if (status.isGranted) {
          return true;
        } else {
          // _showToast('Izin $permissionName ditolak. Beberapa fitur mungkin tidak berfungsi.');
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        // _showToast(
        //     'Izin $permissionName ditolak secara permanen. Buka pengaturan untuk mengaktifkannya.');
        await openAppSettings();
      }
    } catch (e) {
      // _showToast('Terjadi kesalahan saat meminta izin $permissionName.');
    }

    return false;
  }

  /// Meminta izin lokasi (hanya saat digunakan)
  Future<bool> requestLocationPermission() async {
    return _requestPermission(Permission.location, 'Lokasi');
  }
}
