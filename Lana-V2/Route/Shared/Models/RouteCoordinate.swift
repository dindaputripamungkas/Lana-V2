//
//  RouteCoordinate.swift
//  Lana-V2
//
//  Created by Imam on 07/09/26.
//

import Foundation

struct RouteCoordinate: Hashable, Codable {
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}
