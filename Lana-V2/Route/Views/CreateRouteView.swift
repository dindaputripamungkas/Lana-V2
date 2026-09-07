//
//  CreateRouteView.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import SwiftUI

struct CreateRouteView: View {

    @State private var viewModel = CreateRouteViewModel(
        service: PreviewRouteGenerationService()
    )

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    RouteTypeSelector(
                        selectedRouteType: $viewModel.selectedRouteType
                    )
                    
                    RouteInputField(
                        text: $viewModel.distanceText
                    )
                    
                    if viewModel.selectedRouteType == .pointToPoint {
                        WaypointInputView(
                            startLocation: $viewModel.startLocation,
                            finishLocation: $viewModel.finishLocation
                        )
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }

                    PrimaryRouteButton(
                        title: "Create Route",
                        isEnabled: true,
                        action: {
                            viewModel.generateOptions()
                        }
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(isPresented: $viewModel.isShowingRouteOptions) {
                RouteOptionsView(
                    options: viewModel.generatedOptions,
                    onSelect: { option in
                        viewModel.selectedOption = option
                    }
                )
            }
            .navigationDestination(item: $viewModel.selectedOption) { option in
                RouteDetailView(option: option)
            }
        }
    }
}

#Preview {
    CreateRouteView()
    
}
