//
//  SavedRoutesController.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import Foundation
import Observation

@Observable
class SavedRoutesController {
    //mock data
    var routes: [Route] = [
        Route(title: "Loop Route 1", distanceKm: 15.2, durationMinutes: 41, isFavorite: true),
        Route(title: "Downtown Sprint", distanceKm: 8.5, durationMinutes: 25, isFavorite: false),
        Route(title: "Riverside Trail", distanceKm: 22.0, durationMinutes: 60, isFavorite: true)
    ]
    
    func toggleFavorite(for route: Route) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index].isFavorite.toggle()
        }
    }
    
    var selectedOption = 0
    
    var searchText = ""
    
    var filteredRoutes: [Route] {
        let tabFiltered =
        selectedOption == 1 ? routes.filter({$0.isFavorite}) : routes
        if searchText.isEmpty {
            return tabFiltered
        } else {
            return tabFiltered.filter({
                $0.title.lowercased().contains(searchText.lowercased())
            })
        }
    }
}
