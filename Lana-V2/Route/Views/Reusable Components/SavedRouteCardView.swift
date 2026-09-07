//
//  SavedRouteCardView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import SwiftUI

struct SavedRouteCardView: View {
    let route: Route
    var showFavoriteButton: Bool = true
    var onFavoriteToggle:  (() -> Void)? = nil 
    
    var body: some View {
        
        HStack {
            VStack(alignment: .leading){
                Text (route.title)
                Text("\(String(format: "%1.f", route.distanceKm)) km | \(String(format: "%1.f", route.durationMinutes)) min")
                
            }
            Spacer()
            
            if showFavoriteButton {
                Button(action: {
                    onFavoriteToggle?()
                }) {
                    Image(systemName: route.isFavorite ? "star.fill" : "star")
                        .foregroundColor(route.isFavorite ? .gray: .gray)
                }
            }
            
        }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

    }
}

#Preview {
    SavedRouteCardView(
        route: Route(
            title: "Loop Route 1",
            distanceKm: 15.2,
            durationMinutes: 41,
            isFavorite: true
        ),
        onFavoriteToggle: {
            print("Toggled favorite!")
        }
    )
    .padding()
}
