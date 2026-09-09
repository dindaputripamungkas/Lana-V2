//
//  RouteDetailView.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import SwiftUI

struct RouteDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let option: Route

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        routeStatusView
                        mainStatsCard
                        weatherCard
                        overviewCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }

                actionButtons
            }
        }
        .toolbar{
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    private var routeStatusView: some View {
        HStack(alignment: .top, spacing: 12) {
            Label(option.warningMessage, systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 12)

            Label(option.routeKindTitle, systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white)
                .clipShape(Capsule())
        }
    }

    private var mainStatsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                statBlock(
                    title: "Distance",
                    value: String(format: "%.1f km", option.distanceKm)
                )

                Spacer()

                statBlock(
                    title: "Intersections",
                    value: "\(option.intersections)"
                )
            }

//            statBlock(
//                title: "Estimated Time",
//                value: option.durationMinutes
//            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var weatherCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Weather")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Label(option.currentWeather, systemImage: "cloud.sun.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            statBlock(
                title: "Wind",
                value: option.windSpeed
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(option.title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(option.overview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
            } label: {
                Label("Navigate", systemImage: "paperplane.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)

            Button {
            } label: {
                Label("Save For Later", systemImage: "bookmark")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color(.systemGroupedBackground))
    }

    private func statBlock(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    RouteDetailView(
        option: Route(
            title: "Loop Route 15K",
            distanceKm: 15.1,
            durationMinutes: 34,
            intersections: 10,
            badgeTitle: "Closest to Target Distance",
            routeKindTitle: "Loop Route",
            warningMessage: "Cycling road data is not available in your region",
            currentWeather: "26°C",
            windSpeed: "13 km/h",
            overview: "A balanced route option that stays close to your target distance while keeping the path simple for a first preview."
        )
    )
}
