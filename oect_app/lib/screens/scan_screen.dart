import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:OECT/screens/GraphScreen.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanButtonFadeInAnimation;
  late Animation<double> _listFadeInAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  late StreamSubscription<List<ScanResult>> _scanSubscription;
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late StreamController<double> _dataStreamController;
  late Stream<double> _dataStream;

  @override
  void initState() {
    super.initState();
    _startScan();

    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _backgroundColorAnimation = ColorTween(begin: Colors.black, end: Color.fromRGBO(0, 51, 102, 1)).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0, 0.5, curve: Curves.easeInOut)),
    );

    _scanButtonFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.5, 1, curve: Curves.easeInOut)),
    );

    _listFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.5, 1, curve: Curves.easeInOut)),
    );

    _dataStreamController = StreamController<double>.broadcast();
    _dataStream = _dataStreamController.stream;

    _controller.forward();
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    _dataStreamController.close();
    _controller.dispose();
    super.dispose();
  }

  void _startScan() async {
    if (!await Permission.bluetoothScan.request().isGranted ||
        !await Permission.bluetoothConnect.request().isGranted ||
        !await Permission.locationWhenInUse.request().isGranted) {
      return;
    }

    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      return;
    }

    try {
      setState(() {
        _isScanning = true;
        _scanResults.clear();
      });

      await FlutterBluePlus.startScan();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.name.isNotEmpty && result.device.name != "Unnamed Device") {
            if (!_scanResults.contains(result)) {
              setState(() {
                _scanResults.add(result);
              });
              print("Device found: ${result.device.name} - ${result.device.id}");
            }
          }
        }
      });

      await Future.delayed(Duration(seconds: 2));
      await FlutterBluePlus.stopScan();

      setState(() {
        _isScanning = false;
      });

      _animateDevices();
    } catch (e) {
      print("Error during scan: $e");
    }
  }

  void _animateDevices() {
    _listKey.currentState?.removeItem(0, (context, animation) => SizedBox.shrink());

    Future.delayed(Duration(milliseconds: 500), () {
      for (int i = 0; i < _scanResults.length; i++) {
        Future.delayed(Duration(milliseconds: i * 1000), () {
          _listKey.currentState?.insertItem(i);
        });
      }
    });
  }

  void _connectAndMoveToGraphScreen(ScanResult result) async {
    var selectedDevice = result.device;
    try {
      setState(() {
        _isScanning = false;
      });

      print("Connecting to device: ${selectedDevice.id}");
      await selectedDevice.connect();

      var services = await selectedDevice.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.read) {
            var value = await characteristic.read();
            String valueStr = String.fromCharCodes(value).trim();
            print("Read value: '$valueStr'");

            RegExp regex = RegExp(r'[-+]?\d*\.?\d+');
            Iterable<Match> matches = regex.allMatches(valueStr);
            if (matches.isNotEmpty) {
              String numericValueStr = matches.first.group(0)!;
              double? numericValue = double.tryParse(numericValueStr);

              if (numericValue != null && numericValue <= 3.3) {
                _dataStreamController.add(numericValue); 
              }
            }
          }

          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);

            characteristic.value.listen((value) {
              String sensorData = String.fromCharCodes(value).trim();
              print("Received data: '$sensorData'");

              RegExp regex = RegExp(r'[-+]?\d*\.?\d+');
              Iterable<Match> matches = regex.allMatches(sensorData);
              if (matches.isNotEmpty) {
                String numericValueStr = matches.first.group(0)!;
                double? numericValue = double.tryParse(numericValueStr);

                if (numericValue != null && numericValue <= 3.3) {
                  _dataStreamController.add(numericValue);
                }
              }
            });
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${selectedDevice.name}')),
      );

      // Navigate to GraphScreen with dataStream and samplesQueue
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GraphScreen(dataStream: _dataStream),
        ),
      );
    } catch (e) {
      print("Error connecting to device: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${selectedDevice.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColorAnimation.value,
          body: FadeTransition(
            opacity: _scanButtonFadeInAnimation,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                _isScanning
                    ? SizedBox()
                    : _scanResults.isEmpty
                        ? Expanded(
                            child: Center(
                              child: Text(
                                '',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ),
                          )
                        : Expanded(
                            child: FadeTransition(
                              opacity: _listFadeInAnimation,
                              child: AnimatedList(
                                key: _listKey,
                                initialItemCount: 0,
                                itemBuilder: (context, index, animation) {
                                  var result = _scanResults[index];
                                  return FadeTransition(
                                    opacity: animation,
                                    child: Card(
                                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      elevation: 10,
                                      shadowColor: Colors.black.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      color: Colors.white,
                                      child: ListTile(
                                        leading: Icon(Icons.bluetooth, color: Color(0xFF040273)),
                                        title: Text(
                                          result.device.name.isEmpty ? 'Unnamed Device' : result.device.name,
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF040273)),
                                        ),
                                        subtitle: Text(
                                          "ID: ${result.device.id}\nRSSI: ${result.rssi} dBm",
                                          style: TextStyle(color: Color(0xFF040273)),
                                        ),
                                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF040273)),
                                        onTap: () {
                                          _connectAndMoveToGraphScreen(result);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
              ],
            ),
          ),
        );
      },
    );
  }
}
