//
//  SavedRouteCardView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import SwiftUI

struct SavedRouteCardView: View {
    let route: SavedRoute
    var showFavoriteButton: Bool = true
    var onFavoriteToggle:  (() -> Void)? = nil 
    
    var body: some View {
        
        HStack {
            VStack(alignment: .leading){
                Text (route.title)
                Text("\(String(format: "%1.f", route.distance)) km | \(String(format: "%1.f", route.duration)) min")
                
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
        route: SavedRoute(
            title: "Loop Route 1",
            distance: 15.2,
            duration: 41,
            isFavorite: true
        ),
        onFavoriteToggle: {
            print("Toggled favorite!")
        }
    )
    .padding()
}
