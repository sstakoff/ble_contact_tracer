//
//  ContactTracerPeripheral.swift
//  ble_contact_tracer
//
//  Created by Stu Stakoff on 4/11/20.
//

import Foundation
import CoreBluetooth


class CTPeripheral : NSObject, CBPeripheralManagerDelegate {
    
    private static var instance: CTPeripheral!
    private var poweredOn = false
    private var ready = false
    private var shouldAdvertiseWhenReady = false;
    private var shouldAStopAdvertisingWhenPoweredOn = false;
    private var deviceUdid: String!
    
    private var _periphMgr: CBPeripheralManager!
    
    public static func createPeripheral(deviceUdid: String) {
        instance = CTPeripheral()
        instance.deviceUdid = deviceUdid
    }
    
    public static func startAdvertising() {
        if (instance.ready == false) {
            instance.shouldAdvertiseWhenReady = true
            return
        }
                
        let advertData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: kCTLocalName,
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: kCTServiceUuid)]
        ]
        
        if (instance._periphMgr.isAdvertising) {
            print("Already advertising - no need to advertise again")
            return
        }

        instance._periphMgr.startAdvertising(advertData)
    }
    
    public static func stopAdvertising() {
        if (instance.poweredOn == false) {  
            print("Stop advertising request deferred until power is on")
            instance.shouldAStopAdvertisingWhenPoweredOn = true
            return
        }
        if (instance._periphMgr.isAdvertising) {
            instance._periphMgr.stopAdvertising()
        }
    }
    
    public static func isAdvertising() -> Bool {
        return instance._periphMgr.isAdvertising
    }

    
    override init() {
        super.init()
        _periphMgr = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionRestoreIdentifierKey: kCTPeriphManagerRestoreId])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("Restored peripheral manager state")
    }
    
    private func createServices() {
        let svc = CBMutableService(type: CBUUID(string: kCTServiceUuid), primary: true)
        let chr = CBMutableCharacteristic(type: CBUUID(string: kCTDeviceUdidCharacteristicUuid), properties: .read, value: deviceUdid.data(using: .utf8), permissions: .readable)
        svc.characteristics = [chr]
        _periphMgr.add(svc)
        
    }
    
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheral.state == .poweredOn) {
            poweredOn = true
            createServices()
        }
        
        if (shouldAStopAdvertisingWhenPoweredOn) {
            shouldAStopAdvertisingWhenPoweredOn = false
            CTPeripheral.stopAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if (error != nil) {
            print("Could not add service: \(error.debugDescription)")
            return
        }
        
        ready = true
        if (shouldAdvertiseWhenReady) {
            CTPeripheral.startAdvertising()
        }
    }
    
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if (error != nil) {
            print("Error when trying to advertise")
            print(error.debugDescription)
            return
        }
        
        print("Now advertising")
    }
}
