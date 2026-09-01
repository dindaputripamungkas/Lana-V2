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
    var routes: [SavedRoute] = [
        SavedRoute(title: "Loop Route 1", distance: 15.2, duration: 41, isFavorite: true),
        SavedRoute(title: "Downtown Sprint", distance: 8.5, duration: 25, isFavorite: false),
        SavedRoute(title: "Riverside Trail", distance: 22.0, duration: 60, isFavorite: true)
    ]
    
    func toggleFavorite(for route: SavedRoute) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index].isFavorite.toggle()
        }
    }
    
    var selectedOption = 0
    
    var searchText = ""
    
    var filteredRoutes: [SavedRoute] {
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
