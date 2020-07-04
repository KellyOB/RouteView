//
//  ParkingSpot.swift
//  RouteView
//
//  Created by Kelly O'Brien on 6/26/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import UIKit
import MapKit

class Route: NSObject, MKAnnotation {
    let coordinateType: CoordinateType
    //let title: String? = "We Started Here"
    //let subtitle: String? = "Tap for directions."
    let coordinate: CLLocationCoordinate2D
    
    
    init(coordinateType: CoordinateType, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.coordinateType = coordinateType
    }
}

enum CoordinateType {
    case start
    case end
}
