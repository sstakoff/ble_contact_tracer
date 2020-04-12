import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ble_contact_tracer/ble_contact_tracer.dart';
import 'package:flutter_udid/flutter_udid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _udid = 'Unknown';
  bool _isScanning;
  bool _isAdvertising;
  bool _scanChangePending = true;
  bool _advertChangePending = true;
  StreamSubscription _streamSubscription;

  List<DeviceInfo> _discoveredDevices;

  @override
  void initState() {
    super.initState();
    _discoveredDevices = List();
    _isAdvertising = _isScanning = false;
    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
  }


  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String udid = await FlutterUdid.consistentUdid;
    await BleContactTracer.initializePlugin(deviceUdid: udid);

    Future.delayed(Duration(milliseconds: 1500)).then((value) async {
      _isAdvertising  = await BleContactTracer.isAdvertising();
      _isScanning = await BleContactTracer.isScanning();
      if (mounted) {
        setState(() {
          _scanChangePending = _advertChangePending = false;
          _isScanning = _isScanning;
          _isAdvertising = _isAdvertising;
        });
      }

    });


    _streamSubscription = BleContactTracer.discoveredDevices.listen((info) {
      var prevFoundDevice = _discoveredDevices.firstWhere((element) => element.udid == info.udid, orElse: ()=>null);

      if (prevFoundDevice == null) {
        _discoveredDevices.add(info);
      } else {
        prevFoundDevice.rssi = info.rssi;
        prevFoundDevice.lat = info.lat;
        prevFoundDevice.lon = info.lon;
        prevFoundDevice.horizontalAccuracy = info.horizontalAccuracy;
      }
      if (mounted) {
        setState(() {});
      }

    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _udid = udid;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color _advertColor, _scanColor;
    if (_advertChangePending) {
      _advertColor = Colors.amber;
    } else _advertColor = _isAdvertising ? Colors.green : Colors.red;

    if (_scanChangePending) {
      _scanColor = Colors.amber;
    } else _scanColor = _isScanning ? Colors.green : Colors.red;


    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Contact Tracer Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('My UDID: ${_udid.substring(0,min(10, _udid.length))}', textAlign: TextAlign.start,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      child: Text('Scan'),
                      color: _scanColor,
                      onPressed: () async {
                        if (_scanChangePending) return;
                        setState(() {
                          _scanChangePending = true;
                        });
                        if (_isScanning)
                          await BleContactTracer.stopScanning();
                        else
                          await BleContactTracer.scanForDevices();
                        await Future.delayed(Duration(milliseconds: 500));
                        bool scanning = await BleContactTracer.isScanning();
                        setState(() {
                          _isScanning = scanning;
                          _scanChangePending = false;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      child: Text('Advertise'),
                      color: _advertColor,
                      onPressed: () async {
                        if (_advertChangePending) return;
                        setState(() {
                          _advertChangePending = true;
                        });
                        if (_isAdvertising)
                          await BleContactTracer.stopAdvertising();
                        else
                          await BleContactTracer.advertiseMyDevice();
                        await Future.delayed(Duration(milliseconds: 500));
                        bool advert = await BleContactTracer.isAdvertising();
                        setState(() {
                          _isAdvertising = advert;
                          _advertChangePending = false;
                        });

                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      child: Text('Clear'),
                      onPressed: () {
                        setState(() {
                          _discoveredDevices.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Text('Discovered Devices'),
              _discoveredDevices.length == 0 ? Container() : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, idx) {
                    return Text('${_discoveredDevices[idx].udid.substring(0,10)}: Strength: ${_discoveredDevices[idx].rssi} at: ${_discoveredDevices[idx].lat.toStringAsFixed(3)}, ${_discoveredDevices[idx].lon.toStringAsFixed(3)} : Within: ${_discoveredDevices[idx].horizontalAccuracy.toStringAsFixed(1)}');
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
