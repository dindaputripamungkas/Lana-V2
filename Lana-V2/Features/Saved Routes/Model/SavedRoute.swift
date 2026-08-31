//
//  SavedRoute.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import Foundation

struct SavedRoute: Identifiable {
    var id: UUID = UUID()
    var title: String
    var distance: Double
    var duration: Double
    var isFavorite: Bool
}
