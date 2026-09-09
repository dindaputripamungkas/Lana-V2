//
//  SavedRoutesView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas on 31/08/26.
//

import SwiftUI

struct SavedRoutesView: View {
    @Environment(SavedRoutesController.self) private var controller
    @State private var selectedRoute: Route?

    var body: some View {
        @Bindable var controller = controller

        VStack(spacing: 16) {
            Picker("Option", selection: $controller.selectedOption) {
                Text("All").tag(0)
                Text("Favorites").tag(1)
            }
            .pickerStyle(.segmented)
            .tint(RouteTheme.accent)

            if let error = controller.storageErrorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(RouteTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if controller.filteredRoutes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(controller.filteredRoutes) { route in
                            SavedRouteCardView(
                                route: route,
                                onSelect: {
                                    selectedRoute = route
                                },
                                onFavoriteToggle: {
                                    controller.toggleFavorite(for: route)
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Routes")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .background(RouteTheme.background.ignoresSafeArea())
        .searchable(
            text: $controller.searchText,
            prompt: "Search routes..."
        )
        .navigationDestination(item: $selectedRoute) { route in
            RouteDetailView(option: route)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !controller.searchText.isEmpty {
            ContentUnavailableView.search(text: controller.searchText)
        } else {
            ContentUnavailableView(
                controller.selectedOption == 1
                    ? "No Favorite Route"
                    : "No Route",
                systemImage: controller.selectedOption == 1
                    ? "star.slash"
                    : "bookmark.slash",
                description: Text(
                    controller.selectedOption == 1
                        ? "Tap the star on any route to add it to your favorites."
                        : "Routes saved from route details will appear here."
                )
            )
        }
    }
}

#Preview {
    NavigationStack {
        SavedRoutesView()
    }
    .environment(SavedRoutesController.preview)
    .preferredColorScheme(.dark)
}
