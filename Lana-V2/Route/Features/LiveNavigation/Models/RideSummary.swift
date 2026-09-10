//
//  RideSummary.swift
//  Lana-V2
//

import Foundation

struct RideSummary: Identifiable, Equatable {
    let id = UUID()
    let route: Route
    let distanceRiddenMeters: Double
    let elapsedTime: TimeInterval
    let averageSpeedKmh: Double
    let elevationGainMeters: Double
    let averageElevationMeters: Double
}
