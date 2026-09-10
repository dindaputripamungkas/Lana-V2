//
//  RouteCoordinate+MapKit.swift
//  Lana-V2
//

import CoreLocation

extension RouteCoordinate {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
