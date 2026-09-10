//
//  LiveNavigationInstructionCard.swift
//  Lana-V2
//

import SwiftUI

struct LiveNavigationInstructionCard: View {
    let instruction: String
    let distanceMeters: Double
    let progress: Double
    let isRerouting: Bool
    let repeatAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: instructionSymbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(RouteTheme.accent)
                    .clipShape(.rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(distanceText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RouteTheme.accent)

                    Text(instruction)
                        .font(.headline)
                        .foregroundStyle(RouteTheme.primaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                Button(action: repeatAction) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.body.weight(.semibold))
                        .frame(width: 38, height: 38)
                        .background(RouteTheme.surface)
                        .clipShape(Circle())
                }
                .foregroundStyle(RouteTheme.primaryText)
                .accessibilityLabel("Repeat instruction")
            }

            if isRerouting {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(RouteTheme.accent)
                    Text("Finding a new route")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RouteTheme.secondaryText)
                }
            } else {
                ProgressView(value: progress)
                    .tint(RouteTheme.accent)
            }
        }
        .padding(14)
        .background(RouteTheme.background.opacity(0.86))
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RouteTheme.border, lineWidth: 1)
        }
    }

    private var distanceText: String {
        if distanceMeters >= 1_000 {
            return String(format: "%.1f km", distanceMeters / 1_000)
        }
        return "\(Int(distanceMeters.rounded())) m"
    }

    private var instructionSymbol: String {
        let text = instruction.lowercased()

        if text.contains("u-turn") || text.contains("uturn") {
            return "arrow.uturn.backward"
        }
        if text.contains("left") {
            return "arrow.turn.up.left"
        }
        if text.contains("right") {
            return "arrow.turn.up.right"
        }
        if text.contains("arrive") || text.contains("destination") {
            return "flag.checkered"
        }
        if text.contains("roundabout") {
            return "arrow.trianglehead.2.clockwise.rotate.90"
        }
        return "arrow.up"
    }
}
