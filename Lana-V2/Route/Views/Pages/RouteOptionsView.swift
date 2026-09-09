//
//  RouteOptionsView.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import SwiftUI

struct RouteOptionsView: View {
    let options: [Route]
    let onSelect: (Route) -> Void

    var body: some View {
        List {
            Section {
                ForEach(options) { option in
                    RouteOptionCard(option: option) {
                        onSelect(option)
                    }
                    .listRowBackground(RouteTheme.elevatedSurface)
                }
            } header: {
                Text("Best Matches")
            } footer: {
                Text("Ranked by distance accuracy and number of maneuvers.")
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
    }
}

#Preview {
    NavigationStack {
        RouteOptionsView(
            options: [.preview],
            onSelect: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
