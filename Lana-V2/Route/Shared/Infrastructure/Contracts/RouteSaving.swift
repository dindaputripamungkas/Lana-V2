//
//  RouteSaving.swift
//  Lana-V2
//

@MainActor
protocol RouteSaving {
    func save(_ route: Route)
    func isSaved(_ route: Route) -> Bool
    func savedRoute(matching route: Route) -> Route?
    func toggleFavorite(for route: Route)
}
