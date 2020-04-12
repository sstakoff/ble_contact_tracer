import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


class DeviceInfo {
  String udid;
  int rssi;
  double lat;
  double lon;
  double horizontalAccuracy;

  DeviceInfo(this.udid, this.rssi, this.lat, this.lon, this.horizontalAccuracy);
}

class BleContactTracer {
  static BleContactTracer instance;
  MethodChannel _channel;


  StreamController<DeviceInfo> _streamController;

  factory BleContactTracer() {
    return instance;
  }

  static initializePlugin({@required String deviceUdid}) {

    instance = BleContactTracer._internal();
    _initializePlugin(deviceUdid);

  }

  void dispose() {
    _streamController.close();
  }

  BleContactTracer._internal() {
    _channel = MethodChannel('ble_contact_tracer');
    _channel.setMethodCallHandler(_handler);
    _streamController = StreamController<DeviceInfo>.broadcast();
  }

  static Stream<DeviceInfo> get discoveredDevices => instance._streamController.stream;


  static Future<String> get platformVersion async {
    final String version = await instance._channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool>  _initializePlugin(String deviceUdid) async {
    return await instance._channel.invokeMethod('initializePlugin', {'deviceUdid': deviceUdid});
  }

  static Future<bool>  advertiseMyDevice() async {
    return await instance._channel.invokeMethod('advertiseMyDevice');
  }

  static Future<bool>  scanForDevices() async {
    return await instance._channel.invokeMethod('scanForDevices');
  }

  static Future<bool>  stopAdvertising() async {
    return await instance._channel.invokeMethod('stopAdvertising');
  }

  static Future<bool>  stopScanning() async {
    return await instance._channel.invokeMethod('stopScanning');
  }

  static Future<bool>  isAdvertising() async {
    return await instance._channel.invokeMethod('isAdvertising');
  }

  static Future<bool>  isScanning() async {
    return await instance._channel.invokeMethod('isScanning');
  }


  static Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case 'discoveredDevice':
        var args = call.arguments;

        var udid = args['deviceUdid'];
        var rssi = args['rssi'];
        var lat = args['lat'];
        var lon = args['lon'];
        var horizAccuracy = args['horizontalAccuracy'];
        if (instance._streamController.hasListener) {
          instance._streamController.add(DeviceInfo(udid, rssi, lat, lon, horizAccuracy));
        }
        break;
      default:
        print('Got a call for unsupported callback: ${call.method}');
    }
    return true;
  }

}
