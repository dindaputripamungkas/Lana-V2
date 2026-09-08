//
//  RouteCoordinate.swift
//  Lana-V2
//
//  Created by Imam on 07/09/26.
//

import CoreLocation

struct RouteCoordinate: Hashable, Codable {
    let latitude: Double
    let longitude: Double

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isValid: Bool {
        latitude.isFinite && longitude.isFinite
        && CLLocationCoordinate2DIsValid(clCoordinate)
    }
}
