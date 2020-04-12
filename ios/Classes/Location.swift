//
//  Location.swift
//  ble_contact_tracer
//
//  Created by Stu Stakoff on 4/12/20.
//

import Foundation
import CoreLocation

typealias LocationCallback = (_ lat: Double, _ lon: Double) -> Void

@available(iOS 9.0, *)
class CTLocation : NSObject, CLLocationManagerDelegate {
    public static var instance = CTLocation()
    
    private var authorized: Bool = false
    
    private var _locManager: CLLocationManager!
    private var _callbacks: [LocationCallback] = []
    
    override init() {
        super.init()
        
        _locManager = CLLocationManager()
        _locManager.delegate = self
        _locManager.requestWhenInUseAuthorization()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Loc auth: \(status.rawValue)")
        switch (status) {
        case .authorizedAlways:
            authorized = true
            break
        case .authorizedWhenInUse:
            _locManager.requestAlwaysAuthorization()
            break
        case .denied:
            break
        case .notDetermined:
            _locManager.requestAlwaysAuthorization()
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var lat: Double = 0
        var lon: Double = 0;
        if (locations.count > 0) {
            let latest = locations.last
            lat = latest?.coordinate.latitude ?? 0
            lon = latest?.coordinate.longitude ?? 0
        }
        
        for cb in _callbacks {
            cb(lat, lon);
        }
        
        _callbacks.removeAll()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        for cb in _callbacks {
            cb(0, 0);
        }
        
        _callbacks.removeAll()

    }
    
    func getLocation(callback: @escaping LocationCallback) {
        if (!authorized) {
            callback(0,0)
            return
        }
        _callbacks.append(callback)
        _locManager.requestLocation()
    }
    
}
