// DeviceDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceDetailScreen extends StatelessWidget {
  final BluetoothDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Device ID: ${device.id}'),
            Text('Device Name: ${device.name}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await device.disconnect();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Disconnected from ${device.name}')),
                );
                Navigator.pop(context); // Go back to the scan screen
              },
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
