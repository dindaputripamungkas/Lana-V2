//
//  RouteComposerSheet.swift
//  Lana-V2
//
//  Created by Codex on 08/09/26.
//

import SwiftUI
import UIKit

struct RouteComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Bindable var viewModel: CreateRouteViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Cycling", systemImage: "bicycle")
                        .font(.headline)
                        .foregroundStyle(RouteTheme.accent)
                }

                Section("Route Type") {
                    RouteTypeSelector(
                        selectedRouteType: $viewModel.selectedRouteType,
                        showsTitle: false
                    )
                }

                Section("Target Distance") {
                    RouteInputField(
                        text: $viewModel.distanceText,
                        showsTitle: false
                    )
                }

                Section("Waypoints") {
                    WaypointInputView(
                        routeType: viewModel.selectedRouteType,
                        selectedStart: viewModel.selectedStart,
                        selectedFinish: viewModel.selectedFinish,
                        helperMessage: viewModel.pointInstructionMessage,
                        isLocating: viewModel.isLocating,
                        onChooseStart: viewModel.chooseStartPoint,
                        onChooseFinish: viewModel.chooseFinishPoint,
                        onUseCurrentLocation: viewModel.useCurrentLocation,
                        onSwap: viewModel.swapLocations
                    )
                }

                if viewModel.isValidatingDistance {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(RouteTheme.accent)
                            Text("Checking the shortest road distance...")
                                .font(.subheadline)
                                .foregroundStyle(RouteTheme.secondaryText)
                        }
                    }
                } else if let message = viewModel.distanceValidationMessage {
                    Section {
                        Label(
                            message,
                            systemImage: "ruler.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(RouteTheme.accent)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        errorView(
                            message: errorMessage,
                            canOpenSettings: viewModel.canOpenSettings
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(RouteTheme.background)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                    .disabled(viewModel.isGenerating)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryRouteButton(
                    title: viewModel.isGenerating
                        ? "Finding Routes..."
                        : viewModel.isValidatingDistance
                            ? "Checking Distance..."
                            : "Find Your Routes",
                    isEnabled: viewModel.canGenerateRoute,
                    isLoading: viewModel.isGenerating,
                    action: viewModel.generateOptions
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
        .fullScreenCover(item: $viewModel.activePointPicker) { kind in
            RoutePointPickerView(
                kind: kind,
                viewModel: viewModel.makePointPickerViewModel(for: kind)
            ) { location in
                viewModel.setLocation(location, for: kind)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func errorView(
        message: String,
        canOpenSettings: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RouteTheme.danger)

            Text(message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if canOpenSettings {
                Button("Settings") {
                    guard let url = URL(
                        string: UIApplication.openSettingsURLString
                    ) else { return }
                    openURL(url)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RouteTheme.accent)
            }
        }
    }
}

#Preview {
    RouteComposerSheet(
        viewModel: CreateRouteViewModel(
            routeService: PreviewRouteGenerationService(),
            placeSearchService: MapKitPlaceSearchService(),
            locationService: LocationService(),
            locationNamingService: MapKitLocationNamingService()
        )
    )
}
