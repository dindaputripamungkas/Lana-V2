//
//  RouteLeg.swift
//  Lana-V2
//

struct RouteLeg: Hashable {
    let distanceMeters: Double
    let durationSeconds: Double
    let coordinates: [RouteCoordinate]
    let instructions: [String]
}
