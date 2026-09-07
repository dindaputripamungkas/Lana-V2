//
//  RouteTypeSelector.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct RouteTypeSelector: View {
    @Binding var selectedRouteType: RouteType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Type")
                .font(.headline)

            HStack(spacing: 12) {
                RouteTypeCard(
                    icon: "repeat",
                    title: "Loop",
                    description: "Start and finish at the same point.",
                    isSelected: selectedRouteType == .loop,
                    action: {
                        selectedRouteType = .loop
                    }
                )

                RouteTypeCard(
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    title: "A to B",
                    description: "Start here, finish somewhere else.",
                    isSelected: selectedRouteType == .pointToPoint,
                    action: {
                        selectedRouteType = .pointToPoint
                    }
                
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedRouteType: RouteType = .loop

    RouteTypeSelector(
        selectedRouteType: $selectedRouteType
    )
    .padding()
    .background(
        Color(.systemGroupedBackground)
    )
}
