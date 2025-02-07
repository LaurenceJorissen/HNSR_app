import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const BluetoothOffScreen({required this.adapterState, super.key});

  @override
  Widget build(BuildContext context) {
    // You can now use the adapterState variable here
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Off')),
      body: Center(
        child: Text('Bluetooth is ${adapterState.toString()}'),
      ),
    );
  }
}

