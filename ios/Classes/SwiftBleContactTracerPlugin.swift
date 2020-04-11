import Flutter
import UIKit

@available(iOS 9.0, *)
public class SwiftBleContactTracerPlugin: NSObject, FlutterPlugin {
    private static var channel: FlutterMethodChannel!
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "ble_contact_tracer", binaryMessenger: registrar.messenger())
    let instance = SwiftBleContactTracerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
  }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        CTCentral.stopScanning()
        CTPeripheral.stopAdvertising()
    }
    
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch (call.method) {
    case "advertiseMyDevice":
        let args = call.arguments as! [String: String]
        let deviceUdid = args["deviceUdid"] ?? "MY UDID"
        CTPeripheral.createPeripheral(deviceUdid: deviceUdid)
        CTPeripheral.startAdvertising()
        result(true)
        break
    case "scanForDevices":
        CTCentral.createCentral()
        CTCentral.startScanning()
        result(true)
        break
    default:
        result("Unsupported method: \(call.method)")
        break

    }
  }
    
    public static func sendDeviceInfoToDart(deviceUdid: String) {
        channel.invokeMethod("discoveredDevice", arguments: ["deviceUdid": deviceUdid])
    }
}
