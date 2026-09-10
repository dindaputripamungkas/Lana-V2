//
//  RouteDetailsSheet.swift
//  Lana-V2
//

import SwiftUI

struct RouteDetailsSheet: View {
    @Environment(SavedRoutesViewModel.self) private var savedRoutes
    @Bindable var viewModel: RouteDetailViewModel
    @State private var showsDirections = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    RouteRoadInfoView(
                        route: viewModel.route,
                        title: viewModel.roadTitle,
                        message: viewModel.roadMessage
                    )

                    RouteDetailMetricsView(route: viewModel.route)

                    targetDistanceRow
                    waypointSummary

                    RouteWeatherView(weather: viewModel.weather)

                    if !viewModel.route.warningMessage.isEmpty {
                        Label(
                            viewModel.route.warningMessage,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(RouteTheme.primaryText)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RouteTheme.accentMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if !viewModel.route.overview.isEmpty {
                        detailSection(title: "Overview") {
                            Text(viewModel.route.overview)
                                .font(.subheadline)
                                .foregroundStyle(RouteTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    let stats = viewModel.savedRideStats(in: savedRoutes)
                    detailSection(title: "Your Ride Stats") {
                        RouteRideStatsView(
                            averageElevationMeters: stats.elevation,
                            averageSpeedKmh: stats.speed
                        )
                    }

                    if !viewModel.route.navigationSteps.isEmpty {
                        directionsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .background(RouteTheme.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RouteTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.requestFavorite(using: savedRoutes)
                    } label: {
                        Image(systemName: viewModel.isFavorite(in: savedRoutes)
                            ? "star.fill"
                            : "star")
                    }
                    .foregroundStyle(RouteTheme.accent)
                    .accessibilityLabel(
                        viewModel.isFavorite(in: savedRoutes)
                            ? "Remove route from favorites"
                            : "Add route to favorites"
                    )
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actions
            }
        }
        .preferredColorScheme(.dark)
        .tint(RouteTheme.accent)
        .alert("Save Route", isPresented: $viewModel.isNamingRoute) {
            TextField("Route name", text: $viewModel.routeName)
            Button("Cancel", role: .cancel) {
                viewModel.cancelNaming()
            }
            Button("Save") {
                viewModel.saveNamedRoute(using: savedRoutes)
            }
            .disabled(
                viewModel.routeName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )
        } message: {
            Text("Give this route a name so it is easy to find later.")
        }
    }

    private var targetDistanceRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "scope")
                .foregroundStyle(RouteTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Target distance")
                    .font(.caption)
                    .foregroundStyle(RouteTheme.secondaryText)
                Text(
                    "\(viewModel.route.targetDistanceKm, specifier: "%.1f") km"
                )
                .font(.subheadline.weight(.semibold))
            }

            Spacer()

            Text("Gap \(viewModel.targetGapText)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RouteTheme.accent)
        }
        .padding(14)
        .background(RouteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }

    private var waypointSummary: some View {
        VStack(spacing: 0) {
            waypointRow(
                title: viewModel.route.routeType == .loop
                    ? "Start and finish"
                    : "Start",
                name: viewModel.route.startLocation?.name ?? "Start point",
                icon: "location.north.fill"
            )

            if viewModel.route.routeType == .pointToPoint {
                Divider()
                    .overlay(RouteTheme.border)
                    .padding(.leading, 44)
                waypointRow(
                    title: "Finish",
                    name: viewModel.route.finishLocation?.name
                        ?? "Finish point",
                    icon: "mappin"
                )
            }
        }
        .background(RouteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }

    private func waypointRow(
        title: String,
        name: String,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(RouteTheme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RouteTheme.secondaryText)
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RouteTheme.primaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
    }

    private var directionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy) {
                    showsDirections.toggle()
                }
            } label: {
                HStack {
                    Label("Turn-by-turn Directions", systemImage: "list.number")
                        .font(.headline)
                        .foregroundStyle(RouteTheme.primaryText)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RouteTheme.secondaryText)
                        .rotationEffect(.degrees(showsDirections ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsDirections {
                VStack(spacing: 0) {
                    ForEach(
                        Array(viewModel.route.navigationSteps.enumerated()),
                        id: \.offset
                    ) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(width: 24, height: 24)
                                .background(RouteTheme.accent)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(step.instruction)
                                    .font(.subheadline)
                                    .foregroundStyle(RouteTheme.primaryText)

                                Text(distanceText(step.distanceMeters))
                                    .font(.caption)
                                    .foregroundStyle(RouteTheme.secondaryText)
                            }

                            Spacer(minLength: 8)
                        }
                        .padding(12)

                        if index < viewModel.route.navigationSteps.count - 1 {
                            Divider()
                                .overlay(RouteTheme.border)
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(RouteTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(RouteTheme.border)
                }
            }
        }
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(RouteTheme.primaryText)
            content()
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.prepareNavigation()
            } label: {
                Label("Start Ride", systemImage: "bicycle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.white)
            .foregroundStyle(.black)

            Button {
                viewModel.requestSave(using: savedRoutes)
            } label: {
                Label(
                    viewModel.isSaved(in: savedRoutes)
                        ? "Saved"
                        : "Save Route",
                    systemImage: viewModel.isSaved(in: savedRoutes)
                        ? "bookmark.fill"
                        : "bookmark"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 24)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(RouteTheme.primaryText)
            .disabled(viewModel.isSaved(in: savedRoutes))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .background(RouteTheme.background.opacity(0.82))
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1_000 {
            return String(format: "%.1f km", meters / 1_000)
        }
        return "\(Int(meters.rounded())) m"
    }
}
