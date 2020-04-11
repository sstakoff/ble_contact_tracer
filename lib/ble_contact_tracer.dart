import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


class BleContactTracer {
  static BleContactTracer instance;
  MethodChannel _channel;


  StreamController<String> _streamController;

  factory BleContactTracer() {
    return instance;
  }

  static initializePlugin() {

    instance = BleContactTracer._internal();

  }

  BleContactTracer._internal() {
    _channel = MethodChannel('ble_contact_tracer');
    _channel.setMethodCallHandler(_handler);
    _streamController = StreamController<String>.broadcast();
  }

  static Stream<String> get discoveredDevices => instance._streamController.stream;


  static Future<String> get platformVersion async {
    final String version = await instance._channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool>  advertiseMyDevice({@required String deviceUdid}) async {
    return await instance._channel.invokeMethod('advertiseMyDevice', {'deviceUdid': deviceUdid});
  }

  static Future<bool>  scanForDevices() async {
    return await instance._channel.invokeMethod('scanForDevices');
  }

  static Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case 'discoveredDevice':
        var args = call.arguments;

        var udid = args['deviceUdid'];
        if (instance._streamController.hasListener) {
          instance._streamController.add(udid);
        }
        break;
      default:
        print('Got a call for unsupported callback: ${call.method}');
    }
    return true;
  }

}
