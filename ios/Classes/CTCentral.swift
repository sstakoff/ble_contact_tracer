//
//  CTCentral.swift
//  ble_contact_tracer
//
//  Created by Stu Stakoff on 4/11/20.
//

import Foundation
import CoreBluetooth

struct DeviceInfo {
    public var peripheral: CBPeripheral
    public var rssi: NSNumber
    public var lat: Double?
    public var lon: Double?
    public var horizontalAccuracy: Double?
}

@available(iOS 9.0, *)
class CTCentral : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private static var instance: CTCentral!
    private var poweredOn = false
    private var startScanningWhenPoweredOn = false
    private var stopScanningWhenPoweredOn = false

    
    private var _centralMgr: CBCentralManager!
    
    private var _discoveredPeripherals: [UUID: DeviceInfo]!
    
    public static func createCentral() {
        instance = CTCentral()
    }
        
    override init() {
        super.init()
        _discoveredPeripherals = [:]
        _centralMgr = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: kCTCentralManagerRestoreId])
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("Restored central manager state")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            poweredOn = true
            
            if (stopScanningWhenPoweredOn) {
                stopScanningWhenPoweredOn = false
                CTCentral.stopScanning()
            }
            if (startScanningWhenPoweredOn) {
                startScanningWhenPoweredOn = false
                CTCentral.startScanning()
            }
        }
    }
    

    
    public static func startScanning() {
        if (instance.poweredOn == false) {
            print("Start scan request deferred until power is on")
            instance.startScanningWhenPoweredOn = true
            instance.stopScanningWhenPoweredOn = false
            return
        }
        
        if (instance._centralMgr.isScanning) {
            print("Already scanning - no need to scan again")
            return
        }
        
        instance._centralMgr.scanForPeripherals(withServices: [CBUUID(string: kCTServiceUuid)], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
            
        ])
        
        if (instance._centralMgr.isScanning) {
            print("Scanning started....")
        }
    }
    
    public static func stopScanning() {
        if (instance.poweredOn == false) {
            print("Stop scan request deferred until power is on")
            instance.stopScanningWhenPoweredOn = true
            instance.startScanningWhenPoweredOn = false
            return
        }
        
        if (instance._centralMgr.isScanning) {
            instance._centralMgr.stopScan()
        }
    }
    
    public static func isScanning() -> Bool {
        return instance._centralMgr.isScanning
    }

    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered a peripheral: \(peripheral.identifier.uuidString) with RSSI: \(RSSI)")
        
        _discoveredPeripherals[peripheral.identifier] = DeviceInfo(peripheral: peripheral, rssi: RSSI)
        peripheral.delegate = self
        _centralMgr.connect(peripheral, options: nil)
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to the peripheral")
        peripheral.discoverServices([CBUUID(string: kCTServiceUuid)])

    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to the peripheral: \(error.debugDescription)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            print("Error discovering services: \(error.debugDescription)")
            return
        }
        
        let svcCount = peripheral.services?.count ?? 0
        var foundSvc = false
        for idx in (0..<svcCount) {
            let service = peripheral.services![idx]
            if (service.uuid.uuidString.lowercased() == kCTServiceUuid.lowercased()) {
                print("Discovered service on the peripheral")
                foundSvc = true
                peripheral.discoverCharacteristics([CBUUID(string: kCTDeviceUdidCharacteristicUuid)], for: service)
                break
            }
        }
                
        if (!foundSvc) {
            print("Peripheral did not have correct service - cancelling")
            _centralMgr.cancelPeripheralConnection(peripheral)
        }

        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print("Error discovering characteristics: \(error.debugDescription)")
            return
        }
        
        let chCount = service.characteristics?.count ?? 0
        var foundChar = false
        
        for idx in (0..<chCount) {
            let ch = service.characteristics![idx]
            if (ch.uuid.uuidString.lowercased() == kCTDeviceUdidCharacteristicUuid.lowercased()) {
                print("Discovered characteristic on the peripheral")
                foundChar = true
                peripheral.readValue(for: ch)
                break
            }
        }
        
        if (!foundChar) {
            print("Peripheral did not have correct characteristic - cancelling")
            _centralMgr.cancelPeripheralConnection(peripheral)
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error reading characteristic value: \(error.debugDescription)")
            return
        }
        
        let discoveredUDID = String(decoding: characteristic.value!, as: UTF8.self)

        
        print("UDID of discovered device: \(discoveredUDID)")
        

        
        let savedDeviceInfo = _discoveredPeripherals[peripheral.identifier]
        let rssi = savedDeviceInfo?.rssi ?? 0
        
        // Get location info
        CTLocation.instance.getLocation(callback: {(lat: Double, lon: Double, horizontalAccuracy: Double) -> Void in
            SwiftBleContactTracerPlugin.sendDeviceInfoToDart(deviceUdid: discoveredUDID, rssi: rssi, lat: lat, lon: lon, horizontalAccuracy: horizontalAccuracy)
            if (savedDeviceInfo != nil) {
                self._centralMgr.cancelPeripheralConnection(savedDeviceInfo!.peripheral)
                self._discoveredPeripherals.removeValue(forKey: peripheral.identifier)
            }
        })
        

        

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if (error != nil) {
            print("Error disconnecting from peripheral: \(error.debugDescription)")
            return
        }
        
        print("Disconnected from peripheral")

    }
    
    



}
