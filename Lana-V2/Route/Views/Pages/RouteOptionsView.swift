//
//  RouteOptionsView.swift.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import SwiftUI

struct RouteOptionsView: View {
    let options: [Route]
    let onSelect: (Route) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options) { option in
                            RouteCardView(
                                route: option,
                                showBadge: true,
                                showMapPreview: true,
                                onSelect: { onSelect(option) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
            }
        }
    }

}

#Preview {
    NavigationStack {
        let previewService = PreviewRouteGenerationService()
        let generatedOptions = previewService.generateOptions(
            targetDistanceKm: 15,
            routeType: .loop,
            startLocation: nil,
            finishLocation: nil
        )

        RouteOptionsView(
            options: generatedOptions,
            onSelect: { _ in }
        )
    }
}
