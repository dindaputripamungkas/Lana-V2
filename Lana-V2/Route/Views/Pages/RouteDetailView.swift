//
//  RouteDetailView.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import MapKit
import SwiftUI

struct RouteDetailView: View {
    @Environment(SavedRoutesController.self) private var savedRoutes

    let option: Route

    var body: some View {
        List {
            Section {
                routeMap
                    .listRowInsets(EdgeInsets())

                routeIdentity
            }

            if !option.warningMessage.isEmpty {
                Section {
                    Label(
                        option.warningMessage,
                        systemImage: "info.circle.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(RouteTheme.accent)
                }
            }

            Section("Summary") {
                summaryRow(
                    "Distance",
                    value: String(format: "%.1f km", option.distanceKm),
                    icon: "ruler"
                )
                summaryRow("Target gap", value: gapText, icon: "scope")
                summaryRow(
                    "Estimated time",
                    value: option.durationText,
                    icon: "clock"
                )
                summaryRow(
                    "Maneuvers",
                    value: "\(option.intersections)",
                    icon: "arrow.turn.up.right"
                )
            }

            if !option.overview.isEmpty {
                Section("Overview") {
                    Text(option.overview)
                        .font(.subheadline)
                        .foregroundStyle(RouteTheme.secondaryText)
                }
            }

            if !option.instructions.isEmpty {
                Section("Directions") {
                    ForEach(
                        Array(option.instructions.enumerated()),
                        id: \.offset
                    ) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(width: 26, height: 26)
                                .background(RouteTheme.accent)
                                .clipShape(Circle())

                            Text(instruction)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RouteTheme.background)
        .navigationTitle("Route Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(RouteTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
    }

    private var routeMap: some View {
        Map(initialPosition: mapPosition) {
            if option.coordinates.count >= 2 {
                MapPolyline(
                    coordinates: option.coordinates.map(\.clCoordinate)
                )
                .stroke(RouteTheme.accent, lineWidth: 5)
            }

            if let start = option.startLocation {
                Marker(
                    option.routeType == .loop ? "Start / Finish" : "Start",
                    coordinate: start.coordinate.clCoordinate
                )
                .tint(.green)
            }

            if option.routeType == .pointToPoint,
               let finish = option.finishLocation {
                Marker(
                    "Finish",
                    coordinate: finish.coordinate.clCoordinate
                )
                .tint(.red)
            }
        }
        .mapStyle(.standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        ))
        .environment(\.colorScheme, .dark)
        .frame(height: 260)
        .accessibilityLabel("Generated route map")
    }

    private var routeIdentity: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                    .font(.headline)

                Text(option.routeKindTitle)
                    .font(.subheadline)
                    .foregroundStyle(RouteTheme.secondaryText)
            }

            Spacer(minLength: 8)

            Label(
                option.routingModeUsed.title,
                systemImage: option.routingModeUsed == .cycling
                    ? "bicycle"
                    : "car.fill"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(RouteTheme.accent)
        }
    }

    private var saveButton: some View {
        let isSaved = savedRoutes.isSaved(option)

        return Button {
            savedRoutes.save(option)
        } label: {
            Label(
                isSaved ? "Saved" : "Save Route",
                systemImage: isSaved ? "bookmark.fill" : "bookmark"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(.white)
        .foregroundStyle(.black)
        .disabled(isSaved)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func summaryRow(
        _ title: String,
        value: String,
        icon: String
    ) -> some View {
        LabeledContent {
            Text(value)
                .fontWeight(.semibold)
        } label: {
            Label(title, systemImage: icon)
        }
    }

    private var mapPosition: MapCameraPosition {
        let coordinates = option.coordinates.map(\.clCoordinate)

        guard coordinates.count >= 2 else {
            if let coordinate = coordinates.first
                ?? option.startLocation?.coordinate.clCoordinate {
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
        let horizontalPadding = max(rect.size.width * 0.18, 1)
        let verticalPadding = max(rect.size.height * 0.18, 1)
        return .rect(rect.insetBy(
            dx: -horizontalPadding,
            dy: -verticalPadding
        ))
    }

    private var gapText: String {
        let prefix = option.distanceKm >= option.targetDistanceKm ? "+" : "-"
        return "\(prefix)\(String(format: "%.1f", option.distanceGapKm)) km"
    }
}

#Preview {
    NavigationStack {
        RouteDetailView(option: .preview)
    }
    .environment(SavedRoutesController.preview)
    .preferredColorScheme(.dark)
}
