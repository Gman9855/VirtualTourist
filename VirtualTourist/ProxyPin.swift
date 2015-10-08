//
//  ProxyPin.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/8/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import Foundation
import MapKit

class ProxyPin: NSObject, MKAnnotation {
    
    var latitude: Double!
    var longitude: Double!
    var pin: Pin!
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self.latitude, self.longitude)
    }
    
    init(pin: Pin) {
        self.pin = pin
        self.latitude = pin.latitude as Double
        self.longitude = pin.longitude as Double
    }
}
