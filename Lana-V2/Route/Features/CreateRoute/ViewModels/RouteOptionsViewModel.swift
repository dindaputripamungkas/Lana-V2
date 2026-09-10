//
//  RouteOptionsViewModel.swift
//  Lana-V2
//

import Observation

@MainActor
@Observable
final class RouteOptionsViewModel {
    private(set) var options: [Route]
    var selectedRoute: Route?

    init(options: [Route]) {
        self.options = options
    }

    func select(_ route: Route) {
        selectedRoute = route
    }
}
