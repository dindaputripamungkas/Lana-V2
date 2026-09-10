//
//  NavigationRerouting.swift
//  Lana-V2
//

@MainActor
protocol NavigationRerouting {
    func reroute(
        route: Route,
        from currentLocation: RouteLocation,
        to destination: RouteLocation
    ) async throws -> Route
    func cancel()
}
