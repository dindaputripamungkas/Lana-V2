//
//  RouteProgressProjecting.swift
//  Lana-V2
//

@MainActor
protocol RouteProgressProjecting {
    var routeLengthMeters: Double { get }

    func prepare(coordinates: [RouteCoordinate])
    func project(
        _ coordinate: RouteCoordinate,
        minimumProgressMeters: Double
    ) -> RouteProgress?
    func distance(
        from start: RouteCoordinate,
        to finish: RouteCoordinate
    ) -> Double
}
