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
        instance._periphMgr.stopAdvertising()
    }
    
    override init() {
        super.init()
        _periphMgr = CBPeripheralManager()
        _periphMgr.delegate = self
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
