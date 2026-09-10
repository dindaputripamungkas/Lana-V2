//
//  RouteProgress.swift
//  Lana-V2
//

struct RouteProgress: Equatable {
    let distanceAlongRouteMeters: Double
    let distanceFromRouteMeters: Double
    let segmentIndex: Int
    let snappedCoordinate: RouteCoordinate
}
