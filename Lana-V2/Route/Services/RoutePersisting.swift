//
//  RoutePersisting.swift
//  Lana-V2
//

@MainActor
protocol RoutePersisting {
    func loadRoutes() throws -> [Route]
    func saveRoutes(_ routes: [Route]) throws
}

@MainActor
final class InMemoryRouteStore: RoutePersisting {
    private var routes: [Route]

    init(routes: [Route] = []) {
        self.routes = routes
    }

    func loadRoutes() throws -> [Route] {
        routes
    }

    func saveRoutes(_ routes: [Route]) throws {
        self.routes = routes
    }
}
