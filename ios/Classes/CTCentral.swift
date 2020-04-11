//
//  CTCentral.swift
//  ble_contact_tracer
//
//  Created by Stu Stakoff on 4/11/20.
//

import Foundation
import CoreBluetooth

@available(iOS 9.0, *)
class CTCentral : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private static var instance: CTCentral!
    private var poweredOn = false
    private var startScanningWhenPoweredOn = false
    
    private var _centralMgr: CBCentralManager!
    
    private var _discoveredPeripherals: [UUID: CBPeripheral]!
    
    public static func createCentral() {
        instance = CTCentral()
    }
        
    override init() {
        super.init()
        _discoveredPeripherals = [:]
        _centralMgr = CBCentralManager()
        _centralMgr.delegate = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            poweredOn = true
            if (startScanningWhenPoweredOn) {
                CTCentral.startScanning()
            }
        }
    }
    

    
    public static func startScanning() {
        if (instance._centralMgr.isScanning) {
            return
        }
        if (instance.poweredOn == false) {
            instance.startScanningWhenPoweredOn = true
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
        instance._centralMgr.stopScan()
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered a peripheral: \(peripheral.identifier.uuidString) with RSSI: \(RSSI)")
        
        _discoveredPeripherals[peripheral.identifier] = peripheral
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
                
        for service: CBService? in peripheral.services! {
            if (service?.uuid.uuidString.lowercased() == kCTServiceUuid.lowercased()) {
                print("Discovered service on the peripheral")
                peripheral.discoverCharacteristics([CBUUID(string: kCTDeviceUdidCharacteristicUuid)], for: service!)
                break

            }
        }
    
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print("Error discovering characteristics: \(error.debugDescription)")
            return
        }
        
        for ch: CBCharacteristic? in service.characteristics! {
            if (ch?.uuid.uuidString.lowercased() == kCTDeviceUdidCharacteristicUuid.lowercased()) {
                print("Discovered characteristic on the peripheral")
                peripheral.readValue(for: ch!)
                break
            }
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error reading characteristic value: \(error.debugDescription)")
            return
        }
        
        let str = String(decoding: characteristic.value!, as: UTF8.self)

        
        print("Value was: \(str)")
        SwiftBleContactTracerPlugin.sendDeviceInfoToDart(deviceUdid: str)
        
        let savedPeriph = _discoveredPeripherals[peripheral.identifier]
        if (savedPeriph != nil) {
            _centralMgr.cancelPeripheralConnection(savedPeriph!)
            _discoveredPeripherals.removeValue(forKey: peripheral.identifier)
        }

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if (error != nil) {
            print("Error disconnecting from peripheral: \(error.debugDescription)")
            return
        }
        
        print("Disconnected from peripheral")

    }
    
    



}
