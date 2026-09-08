//
//  SavedRoutesView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import SwiftUI

struct SavedRoutesView: View {
@State private var controller = SavedRoutesController()

    var body: some View {
        VStack{
            Picker("Option", selection: $controller.selectedOption){
                Text("All").tag(0)
                Text("Favorites").tag(1)
            }.pickerStyle(.segmented)
            
            if controller.filteredRoutes.isEmpty {
                if !controller.searchText.isEmpty {
                    ContentUnavailableView.search(text: controller.searchText)
                    } else {
                        ContentUnavailableView(
                            controller.selectedOption == 1 ? "No Favorite Route" : "No Route",
                            systemImage: controller.selectedOption == 1 ? "star.slash" : "bookmark.slash",
                            description: Text(
                                controller.selectedOption == 1
                                    ? "Tap the star on any route to add it to your favorites."
                                    : "You haven't saved any routes yet.")
                        )
                    }
            } else {
                ScrollView{
                    LazyVStack{
                        ForEach(controller.filteredRoutes) { route in
                            NavigationLink(destination: RouteDetailView(option: route)) {
                                RouteCardView(
                                    route: route,
                                    showFavoriteButton: true,
                                    showBadge: false,
                                    showMapPreview: true,
                                    onFavoriteToggle: {
                                        controller.toggleFavorite(for: route)
                                    }
                                )
                            }
                            .buttonStyle(.plain)

                        }

                    }
                }
            }
            
        }
        .navigationTitle(Text("Saved Routes"))
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .searchable(text: $controller.searchText,
                    prompt: "Search routes...")
        
    }
}

#Preview {
    SavedRoutesView()
}
