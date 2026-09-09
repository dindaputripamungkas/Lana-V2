//
//  SavedRoutesController.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas on 31/08/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class SavedRoutesController {
    private(set) var routes: [Route]
    var selectedOption = 0
    var searchText = ""
    private(set) var storageErrorMessage: String?

    private let store: any RoutePersisting

    convenience init() {
        self.init(store: UserDefaultsRouteStore())
    }

    init(store: any RoutePersisting) {
        self.store = store

        do {
            routes = try store.loadRoutes()
        } catch {
            routes = []
            storageErrorMessage = error.localizedDescription
        }
    }

    var filteredRoutes: [Route] {
        let tabFiltered = selectedOption == 1
            ? routes.filter(\.isFavorite)
            : routes
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return tabFiltered }
        return tabFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    func save(_ route: Route) {
        guard !isSaved(route) else { return }
        routes.append(route)
        persist()
    }

    func isSaved(_ route: Route) -> Bool {
        routes.contains { $0.id == route.id }
    }

    func toggleFavorite(for route: Route) {
        guard let index = routes.firstIndex(where: { $0.id == route.id }) else {
            return
        }
        routes[index].isFavorite.toggle()
        persist()
    }

    func delete(at offsets: IndexSet) {
        let routeIDs = offsets.map { filteredRoutes[$0].id }
        routes.removeAll { routeIDs.contains($0.id) }
        persist()
    }

    private func persist() {
        do {
            try store.saveRoutes(routes)
            storageErrorMessage = nil
        } catch {
            storageErrorMessage = error.localizedDescription
        }
    }

    static var preview: SavedRoutesController {
        SavedRoutesController(store: InMemoryRouteStore(routes: [
            .preview,
            Route(
                title: "Riverside Ride",
                targetDistanceKm: 22,
                distanceKm: 21.8,
                durationMinutes: 60,
                intersections: 12,
                isFavorite: true
            )
        ]))
    }
}
