//
//  LiveNavigationView.swift
//  Lana-V2
//

import MapKit
import SwiftUI

struct LiveNavigationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LiveNavigationViewModel
    @State private var cameraPosition: MapCameraPosition
    @State private var isHybridMap = false
    @State private var followsUser = true
    @State private var isShowingFinishConfirmation = false

    init(route: Route) {
        _viewModel = State(initialValue: LiveNavigationViewModel(route: route))
        _cameraPosition = State(initialValue: Self.initialCamera(for: route))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if viewModel.routeCoordinates.count >= 2 {
                MapPolyline(
                    coordinates: viewModel.routeCoordinates.map(\.clCoordinate)
                )
                .stroke(
                    RouteTheme.accent,
                    style: StrokeStyle(
                        lineWidth: 7,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }

            if let destinationCoordinate = destinationCoordinate {
                Marker("Finish", coordinate: destinationCoordinate)
                    .tint(RouteTheme.danger)
            }

            if let location = viewModel.latestLocation {
                Annotation(
                    "Current Location",
                    coordinate: location.coordinate.clCoordinate,
                    anchor: .center
                ) {
                    LiveNavigationUserMarker(
                        headingDegrees: location.courseDegrees
                            ?? location.headingDegrees
                            ?? 0
                    )
                }
            }
        }
        .mapStyle(isHybridMap ? .hybrid : .standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        ))
        .mapControlVisibility(.hidden)
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, spacing: 0) {
            topContent
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LiveNavigationControls(
                elapsedTime: viewModel.formattedElapsedTime,
                speedKmh: viewModel.currentSpeedKmh,
                distanceLeftMeters: viewModel.distanceLeftMeters,
                isPaused: viewModel.isPaused,
                pauseAction: viewModel.togglePause,
                finishAction: {
                    isShowingFinishConfirmation = true
                }
            )
        }
        .overlay(alignment: .trailing) {
            mapControls
        }
        .task {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.latestLocation) { _, sample in
            guard followsUser, let sample else { return }
            updateFollowCamera(with: sample)
        }
        .confirmationDialog(
            "Finish this ride?",
            isPresented: $isShowingFinishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finish Ride") {
                viewModel.finishRide()
            }
            Button("Keep Riding", role: .cancel) {}
        } message: {
            Text("Your current ride statistics will be shown in the summary.")
        }
        .sheet(item: summaryBinding) { summary in
            RideSummaryView(summary: summary) {
                viewModel.dismissSummary()
                dismiss()
            }
            .interactiveDismissDisabled()
        }
    }

    private var topContent: some View {
        VStack(spacing: 10) {
            HStack {
                circleButton(
                    systemImage: "xmark",
                    accessibilityLabel: "End navigation"
                ) {
                    isShowingFinishConfirmation = true
                }

                Spacer()

                Text(viewModel.activeRoute.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RouteTheme.primaryText)
                    .lineLimit(1)

                Spacer()

                circleButton(
                    systemImage: viewModel.isVoiceEnabled
                        ? "speaker.wave.2.fill"
                        : "speaker.slash.fill",
                    accessibilityLabel: viewModel.isVoiceEnabled
                        ? "Mute voice guidance"
                        : "Enable voice guidance"
                ) {
                    viewModel.toggleVoice()
                }
            }

            LiveNavigationInstructionCard(
                instruction: viewModel.currentInstruction,
                distanceMeters: viewModel.distanceToNextStepMeters,
                progress: viewModel.routeProgressFraction,
                isRerouting: viewModel.isRerouting,
                repeatAction: viewModel.repeatInstruction
            )

            if let error = viewModel.locationErrorMessage {
                Label(error, systemImage: "location.slash.fill")
                    .font(.caption)
                    .foregroundStyle(RouteTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RouteTheme.danger.opacity(0.82))
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var mapControls: some View {
        VStack(spacing: 10) {
            circleButton(
                systemImage: isHybridMap ? "map.fill" : "globe.americas.fill",
                accessibilityLabel: "Change map style"
            ) {
                isHybridMap.toggle()
            }

            circleButton(
                systemImage: "location.fill",
                accessibilityLabel: "Recenter map"
            ) {
                followsUser = true
                if let location = viewModel.latestLocation {
                    updateFollowCamera(with: location)
                } else {
                    cameraPosition = Self.initialCamera(
                        for: viewModel.activeRoute
                    )
                }
            }
        }
        .padding(.trailing, 16)
        .offset(y: 70)
    }

    private func circleButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(RouteTheme.primaryText)
                .frame(width: 44, height: 44)
                .background(RouteTheme.background.opacity(0.82))
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(RouteTheme.border, lineWidth: 1)
                }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func updateFollowCamera(
        with sample: NavigationLocationSample
    ) {
        let heading = sample.courseDegrees ?? sample.headingDegrees ?? 0
        withAnimation(.linear(duration: 0.35)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: sample.coordinate.clCoordinate,
                distance: 850,
                heading: heading,
                pitch: 52
            ))
        }
    }

    private var destinationCoordinate: CLLocationCoordinate2D? {
        if viewModel.activeRoute.routeType == .loop {
            return viewModel.activeRoute.startLocation?.coordinate.clCoordinate
        }
        return viewModel.activeRoute.finishLocation?.coordinate.clCoordinate
    }

    private var summaryBinding: Binding<RideSummary?> {
        Binding(
            get: { viewModel.summary },
            set: { newValue in
                if newValue == nil {
                    viewModel.dismissSummary()
                }
            }
        )
    }

    private static func initialCamera(for route: Route) -> MapCameraPosition {
        let coordinates = route.coordinates.map(\.clCoordinate)
        guard coordinates.count >= 2 else {
            if let coordinate = coordinates.first
                ?? route.startLocation?.coordinate.clCoordinate {
                return .camera(MapCamera(
                    centerCoordinate: coordinate,
                    distance: 2_000
                ))
            }
            return .automatic
        }

        let polyline = MKPolyline(
            coordinates: coordinates,
            count: coordinates.count
        )
        let rect = polyline.boundingMapRect
        return .rect(rect.insetBy(
            dx: -max(rect.size.width * 0.2, 1),
            dy: -max(rect.size.height * 0.2, 1)
        ))
    }
}

#Preview {
    LiveNavigationView(route: .preview)
        .preferredColorScheme(.dark)
}
