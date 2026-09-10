//
//  RoutePointPickerView.swift
//  Lana-V2
//

import MapKit
import SwiftUI
import UIKit

struct RoutePointPickerView: View {
    let kind: RoutePointPickerKind
    let onConfirm: (RouteLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @FocusState private var isSearchFocused: Bool
    @State private var viewModel: RoutePointPickerViewModel
    @State private var cameraPosition: MapCameraPosition
    @State private var isDraggingPin = false

    init(
        kind: RoutePointPickerKind,
        viewModel: RoutePointPickerViewModel,
        onConfirm: @escaping (RouteLocation) -> Void
    ) {
        self.kind = kind
        self.onConfirm = onConfirm
        _viewModel = State(initialValue: viewModel)
        if let coordinate = viewModel.selectedLocation?.coordinate {
            _cameraPosition = State(
                initialValue: Self.cameraPosition(for: coordinate)
            )
        } else {
            _cameraPosition = State(
                initialValue: .userLocation(fallback: .automatic)
            )
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack(alignment: .top) {
                pickerMap
                searchPanel
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                confirmationBar
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RouteTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectCurrentLocation()
                    } label: {
                        if viewModel.isLocating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                        }
                    }
                    .disabled(viewModel.isLocating)
                    .accessibilityLabel("Use current location")
                }
            }
            .task {
                guard viewModel.selectedLocation == nil else { return }
                await viewModel.useCurrentLocation()
                if let coordinate = viewModel.selectedLocation?.coordinate {
                    moveCamera(to: coordinate)
                }
            }
            .onDisappear {
                viewModel.cancelRequests()
            }
        }
        .preferredColorScheme(.dark)
        .tint(RouteTheme.accent)
    }

    private var pickerMap: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let selectedLocation = viewModel.selectedLocation {
                    Annotation(
                        "Selected point",
                        coordinate: selectedLocation.coordinate.clCoordinate,
                        anchor: .bottom
                    ) {
                        draggablePin(proxy: proxy)
                    }
                }
            }
            .mapStyle(.standard(
                elevation: .flat,
                emphasis: .muted,
                pointsOfInterest: .all,
                showsTraffic: false
            ))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .environment(\.colorScheme, .dark)
            .onMapCameraChange(frequency: .onEnd) { context in
                let region = context.region
                viewModel.updateVisibleRegion(PlaceSearchRegion(
                    center: RouteCoordinate(
                        latitude: region.center.latitude,
                        longitude: region.center.longitude
                    ),
                    latitudeDelta: region.span.latitudeDelta,
                    longitudeDelta: region.span.longitudeDelta
                ))
            }
            .onTapGesture(coordinateSpace: .local) { point in
                guard !isDraggingPin,
                      let coordinate = proxy.convert(
                        point,
                        from: .local
                      ) else { return }
                isSearchFocused = false
                viewModel.selectCoordinate(RouteCoordinate(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var searchPanel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(RouteTheme.secondaryText)

                TextField(
                    "Search an address or place",
                    text: Binding(
                        get: { viewModel.query },
                        set: viewModel.updateQuery
                    )
                )
                .focused($isSearchFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(RouteTheme.primaryText)
                .tint(RouteTheme.accent)

                if viewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                } else if !viewModel.query.isEmpty {
                    Button {
                        viewModel.updateQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(RouteTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(.ultraThinMaterial)
            .background(RouteTheme.background.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSearchFocused
                            ? RouteTheme.accent.opacity(0.8)
                            : RouteTheme.border
                    )
            }

            if !viewModel.suggestions.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.suggestions) { suggestion in
                            suggestionButton(suggestion)

                            if suggestion != viewModel.suggestions.last {
                                Divider()
                                    .overlay(RouteTheme.border)
                                    .padding(.leading, 46)
                            }
                        }
                    }
                }
                .frame(maxHeight: 270)
                .background(.ultraThinMaterial)
                .background(RouteTheme.background.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(RouteTheme.border)
                }
            } else if viewModel.hasCompletedSearch,
                      viewModel.query.trimmingCharacters(
                        in: .whitespacesAndNewlines
                      ).count >= 2,
                      viewModel.errorMessage == nil {
                Text("No places found in this map area.")
                    .font(.caption)
                    .foregroundStyle(RouteTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RouteTheme.background.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let errorMessage = viewModel.errorMessage {
                errorBanner(errorMessage)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func suggestionButton(
        _ suggestion: PlaceSearchSuggestion
    ) -> some View {
        Button {
            isSearchFocused = false
            Task {
                await viewModel.selectSuggestion(suggestion)
                if let coordinate = viewModel.selectedLocation?.coordinate {
                    moveCamera(to: coordinate)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin")
                    .foregroundStyle(RouteTheme.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RouteTheme.primaryText)
                        .lineLimit(1)

                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.caption)
                            .foregroundStyle(RouteTheme.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RouteTheme.accent)

            Text(message)
                .font(.caption)
                .foregroundStyle(RouteTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.canOpenSettings {
                Button("Settings") {
                    guard let url = URL(
                        string: UIApplication.openSettingsURLString
                    ) else { return }
                    openURL(url)
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(12)
        .background(RouteTheme.background.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }

    private var confirmationBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(RouteTheme.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.fieldTitle)
                        .font(.caption)
                        .foregroundStyle(RouteTheme.secondaryText)

                    Text(
                        viewModel.selectedLocation?.name
                            ?? "Tap the map, search, or use GPS"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RouteTheme.primaryText)
                    .lineLimit(2)
                }

                Spacer(minLength: 8)

                if viewModel.isResolvingLocation {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            PrimaryRouteButton(
                title: viewModel.isResolvingLocation
                    ? "Finding Place..."
                    : "Confirm Point",
                isEnabled: viewModel.canConfirm,
                isLoading: viewModel.isResolvingLocation
            ) {
                guard let location = viewModel.selectedLocation else {
                    return
                }
                onConfirm(location)
                dismiss()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .background(RouteTheme.background.opacity(0.82))
    }

    private func selectCurrentLocation() {
        isSearchFocused = false
        Task {
            await viewModel.useCurrentLocation()
            if let coordinate = viewModel.selectedLocation?.coordinate {
                moveCamera(to: coordinate)
            }
        }
    }

    private func moveCamera(to coordinate: RouteCoordinate) {
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = Self.cameraPosition(for: coordinate)
        }
    }

    private static func cameraPosition(
        for coordinate: RouteCoordinate
    ) -> MapCameraPosition {
        .camera(MapCamera(
            centerCoordinate: coordinate.clCoordinate,
            distance: 2_200
        ))
    }

    private func draggablePin(proxy: MapProxy) -> some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 38, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, RouteTheme.accent)
            .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
            .accessibilityLabel("Selected location pin")
            .gesture(
                LongPressGesture(minimumDuration: 0.18)
                    .sequenced(before: DragGesture(
                        minimumDistance: 0,
                        coordinateSpace: .global
                    ))
                    .onChanged { value in
                        guard case .second(true, let drag?) = value,
                              let coordinate = proxy.convert(
                                drag.location,
                                from: .global
                              ) else { return }

                        isDraggingPin = true
                        viewModel.movePin(to: RouteCoordinate(
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        ))
                    }
                    .onEnded { value in
                        if case .second(true, let drag?) = value,
                           let coordinate = proxy.convert(
                            drag.location,
                            from: .global
                           ) {
                            viewModel.finishMovingPin(to: RouteCoordinate(
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude
                            ))
                        }
                        isDraggingPin = false
                    }
            )
    }
}
