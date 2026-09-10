//
//  SavedRoutesView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas on 31/08/26.
//

import SwiftUI

struct SavedRoutesView: View {
    @Environment(SavedRoutesViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 16) {
            Picker("Option", selection: $viewModel.selectedOption) {
                Text("All").tag(0)
                Text("Favorites").tag(1)
            }
            .pickerStyle(.segmented)
            .tint(RouteTheme.accent)

            if let error = viewModel.storageErrorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(RouteTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.filteredRoutes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredRoutes) { route in
                            SavedRouteCardView(
                                route: route,
                                onSelect: {
                                    viewModel.selectedRoute = route
                                },
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(for: route)
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
            text: $viewModel.searchText,
            prompt: "Search routes..."
        )
        .navigationDestination(item: $viewModel.selectedRoute) { route in
            RouteDetailView(option: route)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            ContentUnavailableView(
                viewModel.selectedOption == 1
                    ? "No Favorite Route"
                    : "No Route",
                systemImage: viewModel.selectedOption == 1
                    ? "star.slash"
                    : "bookmark.slash",
                description: Text(
                    viewModel.selectedOption == 1
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
    .environment(SavedRoutesViewModel.preview)
    .preferredColorScheme(.dark)
}
