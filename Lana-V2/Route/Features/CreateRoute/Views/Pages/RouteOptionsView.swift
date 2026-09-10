//
//  RouteOptionsView.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import SwiftUI

struct RouteOptionsView: View {
    @State private var viewModel: RouteOptionsViewModel

    init(options: [Route]) {
        _viewModel = State(
            initialValue: RouteOptionsViewModel(options: options)
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            Section {
                ForEach(viewModel.options) { option in
                    RouteOptionCard(option: option) {
                        viewModel.select(option)
                    }
                    .listRowBackground(RouteTheme.elevatedSurface)
                }
            } header: {
                Text("Best Matches")
            } footer: {
                Text("Ranked by target-distance fit, turns, and estimated time. Cycling options are prioritized.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RouteTheme.background)
        .navigationTitle("Route Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(RouteTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $viewModel.selectedRoute) { route in
            RouteDetailView(option: route)
        }
    }
}

#Preview {
    NavigationStack {
        RouteOptionsView(
            options: [.preview]
        )
    }
    .preferredColorScheme(.dark)
}
