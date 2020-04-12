import Flutter
import UIKit

@available(iOS 9.0, *)
public class SwiftBleContactTracerPlugin: NSObject, FlutterPlugin {
    private static var channel: FlutterMethodChannel!
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "ble_contact_tracer", binaryMessenger: registrar.messenger())
    let instance = SwiftBleContactTracerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // force permission check
    let _ = CTLocation.instance
    
  }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        CTCentral.stopScanning()
        CTPeripheral.stopAdvertising()
    }
    
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch (call.method) {
    case "initializePlugin":
        let args = call.arguments as! [String: String]
        let deviceUdid = args["deviceUdid"] ?? "MISSING UDID"
        CTPeripheral.createPeripheral(deviceUdid: deviceUdid)
        CTCentral.createCentral()
        result(true)
        break
    case "advertiseMyDevice":
        CTPeripheral.startAdvertising()
        result(true)
        break
    case "scanForDevices":
        CTCentral.startScanning()
        result(true)
        break
    case "stopAdvertising":
        CTPeripheral.stopAdvertising()
        result(true)
        break
    case "stopScanning":
        CTCentral.stopScanning()
        result(true)
        break
    case "isAdvertising":
        result(CTPeripheral.isAdvertising())
        break
    case "isScanning":
        result(CTCentral.isScanning())
        break
    default:
        result("Unsupported method: \(call.method)")
        break

    }
  }
    
    public static func sendDeviceInfoToDart(deviceUdid: String, rssi: NSNumber, lat: Double, lon: Double) {
        channel.invokeMethod("discoveredDevice", arguments: [
            "deviceUdid": deviceUdid,
            "rssi": rssi,
            "lat": lat,
            "lon": lon
        ])
    }
}
