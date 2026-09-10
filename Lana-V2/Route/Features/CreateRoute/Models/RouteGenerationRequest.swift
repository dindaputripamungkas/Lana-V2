//
//  RouteGenerationRequest.swift
//  Lana-V2
//

struct RouteGenerationRequest: Hashable {
    let routeType: RouteType
    let targetDistanceMeters: Double
    let start: RouteLocation
    let finish: RouteLocation?

    var targetDistanceKm: Double {
        targetDistanceMeters / 1_000
    }
}
