import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
  await Permission.bluetooth.request();
  await Permission.location.request();
}
