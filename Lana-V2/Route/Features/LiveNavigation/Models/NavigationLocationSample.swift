//
//  NavigationLocationSample.swift
//  Lana-V2
//

import Foundation

enum NavigationLocationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum NavigationLocationEvent: Equatable {
    case authorizationChanged(NavigationLocationAuthorization)
    case sample(NavigationLocationSample)
    case failure(String)
}

struct NavigationLocationSample: Equatable {
    let coordinate: RouteCoordinate
    let timestamp: Date
    let horizontalAccuracyMeters: Double
    let verticalAccuracyMeters: Double
    let altitudeMeters: Double
    let speedMetersPerSecond: Double
    let courseDegrees: Double?
    let headingDegrees: Double?
}
