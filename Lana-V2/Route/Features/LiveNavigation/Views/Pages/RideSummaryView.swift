//
//  RideSummaryView.swift
//  Lana-V2
//

import MapKit
import SwiftUI

struct RideSummaryView: View {
    @Environment(SavedRoutesViewModel.self) private var savedRoutes

    @State private var viewModel: RideSummaryViewModel

    let doneAction: () -> Void

    init(
        summary: RideSummary,
        doneAction: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: RideSummaryViewModel(summary: summary)
        )
        self.doneAction = doneAction
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summaryMap
                        .listRowInsets(EdgeInsets())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ride Complete")
                            .font(.title2.bold())
                        Text(summary.route.title)
                            .font(.subheadline)
                            .foregroundStyle(RouteTheme.secondaryText)
                    }
                    .padding(.vertical, 4)
                }

                Section("Ride Statistics") {
                    metricRow(
                        "Distance",
                        value: String(
                            format: "%.2f km",
                            summary.distanceRiddenMeters / 1_000
                        ),
                        icon: "point.topleft.down.to.point.bottomright.curvepath"
                    )
                    metricRow(
                        "Moving time",
                        value: durationText,
                        icon: "timer"
                    )
                    metricRow(
                        "Average speed",
                        value: String(
                            format: "%.1f km/h",
                            summary.averageSpeedKmh
                        ),
                        icon: "speedometer"
                    )
                    metricRow(
                        "Elevation gain",
                        value: "\(Int(summary.elevationGainMeters.rounded())) m",
                        icon: "mountain.2"
                    )
                    metricRow(
                        "Average elevation",
                        value: "\(Int(summary.averageElevationMeters.rounded())) m",
                        icon: "water.waves.and.arrow.up"
                    )
                }

                Section("Route") {
                    metricRow(
                        "Planned distance",
                        value: String(
                            format: "%.1f km",
                            summary.route.distanceKm
                        ),
                        icon: "ruler"
                    )
                    metricRow(
                        "Navigation mode",
                        value: summary.route.routingModeUsed.title,
                        icon: summary.route.routingModeUsed == .cycling
                            ? "bicycle"
                            : "car.fill"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(RouteTheme.background)
            .navigationTitle("Ride Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RouteTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.save(using: savedRoutes)
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    }
                    .disabled(isSaved)
                    .foregroundStyle(RouteTheme.accent)
                    .accessibilityLabel(isSaved ? "Route saved" : "Save route")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: doneAction) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
        .preferredColorScheme(.dark)
        .tint(RouteTheme.accent)
    }

    private var summaryMap: some View {
        Map(initialPosition: mapPosition) {
            if summary.route.coordinates.count >= 2 {
                MapPolyline(
                    coordinates: summary.route.coordinates.map(\.clCoordinate)
                )
                .stroke(RouteTheme.accent, lineWidth: 5)
            }
        }
        .mapStyle(.standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        ))
        .environment(\.colorScheme, .dark)
        .frame(height: 240)
        .allowsHitTesting(false)
    }

    private func metricRow(
        _ title: String,
        value: String,
        icon: String
    ) -> some View {
        LabeledContent {
            Text(value).fontWeight(.semibold)
        } label: {
            Label(title, systemImage: icon)
        }
    }

    private var durationText: String {
        let seconds = max(0, Int(summary.elapsedTime.rounded(.down)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(
                format: "%d hr %02d min %02d sec",
                hours,
                minutes,
                remainingSeconds
            )
        }
        return String(format: "%d min %02d sec", minutes, remainingSeconds)
    }

    private var isSaved: Bool {
        viewModel.isSaved(in: savedRoutes)
    }

    private var summary: RideSummary {
        viewModel.summary
    }

    private var mapPosition: MapCameraPosition {
        let coordinates = summary.route.coordinates.map(\.clCoordinate)
        guard coordinates.count >= 2 else { return .automatic }

        let polyline = MKPolyline(
            coordinates: coordinates,
            count: coordinates.count
        )
        let rect = polyline.boundingMapRect
        return .rect(rect.insetBy(
            dx: -max(rect.size.width * 0.18, 1),
            dy: -max(rect.size.height * 0.18, 1)
        ))
    }
}

#Preview {
    RideSummaryView(
        summary: RideSummary(
            route: .preview,
            distanceRiddenMeters: 14_860,
            elapsedTime: 2_775,
            averageSpeedKmh: 19.3,
            elevationGainMeters: 128,
            averageElevationMeters: 42
        ),
        doneAction: {}
    )
    .environment(SavedRoutesViewModel.preview)
}
