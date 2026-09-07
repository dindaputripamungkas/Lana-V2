//
//  RouteOptionsView.swift.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import SwiftUI

struct RouteOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    let options: [Route]
    let onSelect: (Route) -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options) { option in
                            RouteOptionCard(option: option) {
                                onSelect(option)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Route Options")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
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
