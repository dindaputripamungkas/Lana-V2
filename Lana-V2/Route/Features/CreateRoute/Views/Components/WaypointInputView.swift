//
//  WaypointInputView.swift
//  Lana-V2
//

import SwiftUI

struct WaypointInputView: View {
    let routeType: RouteType
    let selectedStart: RouteLocation?
    let selectedFinish: RouteLocation?
    let helperMessage: String
    let isLocating: Bool
    let onChooseStart: () -> Void
    let onChooseFinish: () -> Void
    let onUseCurrentLocation: () -> Void
    let onSwap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Waypoints")
                    .font(.headline)

                Spacer()

                if routeType == .pointToPoint {
                    Button(action: onSwap) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .tint(RouteTheme.primaryText)
                    .disabled(selectedStart == nil && selectedFinish == nil)
                    .accessibilityLabel("Swap start and finish")
                }
            }

            HStack(spacing: 8) {
                pointButton(
                    kind: .start,
                    title: routeType == .loop
                        ? "Start and Finish"
                        : "Start Point",
                    location: selectedStart,
                    action: onChooseStart
                )

                Button(action: onUseCurrentLocation) {
                    Group {
                        if isLocating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RouteTheme.primaryText)
                    .frame(width: 50, height: 50)
                    .background(RouteTheme.surface)
                    .clipShape(Circle())
                    .overlay {
                        Circle().strokeBorder(RouteTheme.border)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLocating)
                .accessibilityLabel("Use current location")
            }

            if routeType == .pointToPoint {
                pointButton(
                    kind: .finish,
                    title: "Finish Point",
                    location: selectedFinish,
                    action: onChooseFinish
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Text(helperMessage)
                .font(.caption)
                .foregroundStyle(RouteTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
        }
        .animation(.snappy, value: routeType)
    }

    private func pointButton(
        kind: RoutePointPickerKind,
        title: String,
        location: RouteLocation?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: kind.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(
                        location == nil
                            ? RouteTheme.secondaryText
                            : RouteTheme.accent
                    )
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(RouteTheme.secondaryText)

                    Text(location?.name ?? kind.placeholder)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(
                            location == nil
                                ? RouteTheme.secondaryText
                                : RouteTheme.primaryText
                        )
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RouteTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(RouteTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        location == nil
                            ? RouteTheme.border
                            : RouteTheme.accent.opacity(0.55)
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(location?.name ?? "Not selected")
    }
}

#Preview {
    WaypointInputView(
        routeType: .pointToPoint,
        selectedStart: Route.preview.startLocation,
        selectedFinish: Route.preview.finishLocation,
        helperMessage: "Choose both points so Lana can check the real road distance.",
        isLocating: false,
        onChooseStart: {},
        onChooseFinish: {},
        onUseCurrentLocation: {},
        onSwap: {}
    )
    .padding()
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
