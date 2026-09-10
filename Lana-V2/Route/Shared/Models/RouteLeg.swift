//
//  RouteLeg.swift
//  Lana-V2
//

struct RouteLeg: Hashable {
    let distanceMeters: Double
    let durationSeconds: Double
    let coordinates: [RouteCoordinate]
    let steps: [RouteStep]

    var instructions: [String] {
        steps.map(\.instruction)
    }
}
