//
//  RouteTypeSelector.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct RouteTypeSelector: View {
    @Binding var selectedRouteType: RouteType
    var showsTitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsTitle {
                Text("Route Type")
                    .font(.headline)
            }

            Picker("Route Type", selection: $selectedRouteType) {
                Text("Loop")
                    .tag(RouteType.loop)
                Text("A to B")
                    .tag(RouteType.pointToPoint)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Route type")
        }
    }
}

#Preview {
    @Previewable @State var selectedRouteType: RouteType = .loop

    RouteTypeSelector(
        selectedRouteType: $selectedRouteType
    )
    .padding()
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
