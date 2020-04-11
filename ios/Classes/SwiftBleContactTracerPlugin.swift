import Flutter
import UIKit

@available(iOS 9.0, *)
public class SwiftBleContactTracerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ble_contact_tracer", binaryMessenger: registrar.messenger())
    let instance = SwiftBleContactTracerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    CTPeripheral.createPeripheral(deviceUdid: "MY UDID")
    CTPeripheral.startAdvertising()
    
    CTCentral.createCentral()
    CTCentral.startScanning()
    
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
