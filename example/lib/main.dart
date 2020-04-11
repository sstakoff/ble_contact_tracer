import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ble_contact_tracer/ble_contact_tracer.dart';
import 'package:flutter_udid/flutter_udid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BleContactTracer.initializePlugin();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _udid;

  List<String> _discoveredDevices;

  @override
  void initState() {
    super.initState();
    _discoveredDevices = List();
    BleContactTracer.discoveredDevices.listen((udid) {
      if (_discoveredDevices.contains(udid) == false) {
        _discoveredDevices.add(udid);
        if (mounted) {
          setState(() {});
        }
      }
    });
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String udid = await FlutterUdid.consistentUdid;

    BleContactTracer.advertiseMyDevice(deviceUdid: udid);
    BleContactTracer.scanForDevices();

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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('My UDID: $_udid', textAlign: TextAlign.start,),
              Text('Discovered Devices'),
              _discoveredDevices.length == 0 ? Container() : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, idx) {
                    return Text(_discoveredDevices[idx]);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
