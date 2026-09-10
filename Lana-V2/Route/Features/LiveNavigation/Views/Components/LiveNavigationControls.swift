//
//  LiveNavigationControls.swift
//  Lana-V2
//

import SwiftUI

struct LiveNavigationControls: View {
    let elapsedTime: String
    let speedKmh: Double
    let distanceLeftMeters: Double
    let isPaused: Bool
    let pauseAction: () -> Void
    let finishAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                metric(value: elapsedTime, label: "TIME")
                Divider().overlay(RouteTheme.border)
                metric(
                    value: String(format: "%.1f", speedKmh),
                    label: "KM/H"
                )
                Divider().overlay(RouteTheme.border)
                metric(value: distanceText, label: "LEFT")
            }
            .frame(height: 48)

            HStack(spacing: 12) {
                Button(action: pauseAction) {
                    Label(
                        isPaused ? "Resume" : "Pause",
                        systemImage: isPaused ? "play.fill" : "pause.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 30)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.black)

                Button(action: finishAction) {
                    Label("Finish", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 30)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(RouteTheme.accentMuted)
                .foregroundStyle(RouteTheme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(RouteTheme.background.opacity(0.93))
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RouteTheme.border)
                .frame(height: 1)
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(RouteTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RouteTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var distanceText: String {
        if distanceLeftMeters >= 1_000 {
            return String(format: "%.1f km", distanceLeftMeters / 1_000)
        }
        return "\(Int(distanceLeftMeters.rounded())) m"
    }
}
