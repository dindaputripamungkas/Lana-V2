//
//  WaypointInputView.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct WaypointInputView: View {
    @Binding var startText: String
    @Binding var finishText: String

    let showsFinish: Bool
    var showsTitle = true
    let selectedStart: RouteLocation?
    let selectedFinish: RouteLocation?
    let searchResults: [RouteLocation]
    let activeField: RouteLocationField?
    let searchMessage: String?
    let isSearching: Bool
    let isLocating: Bool
    let onQueryChanged: (String, RouteLocationField) -> Void
    let onFocus: (RouteLocationField) -> Void
    let onSelect: (RouteLocation, RouteLocationField) -> Void
    let onUseCurrentLocation: () -> Void
    let onSwap: () -> Void

    @FocusState private var focusedField: RouteLocationField?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsTitle || showsFinish {
                HStack {
                    if showsTitle {
                        Text("Waypoints")
                            .font(.headline)
                    }

                    Spacer()

                    if showsFinish {
                        Button(action: swapLocations) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel("Swap start and finish")
                    }
                }
            }

            locationField(
                field: .start,
                icon: "circle.fill",
                placeholder: "Start from...",
                text: $startText,
                isSelected: selectedStart != nil
            )

            searchResultsView(for: .start)

            if showsFinish {
                locationField(
                    field: .finish,
                    icon: "mappin.circle.fill",
                    placeholder: "Finish at...",
                    text: $finishText,
                    isSelected: selectedFinish != nil
                )

                searchResultsView(for: .finish)
            }
        }
        .onChange(of: focusedField) { _, field in
            if let field {
                onFocus(field)
            }
        }
    }

    private func locationField(
        field: RouteLocationField,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(
                    isSelected ? RouteTheme.accent : RouteTheme.secondaryText
                )

            TextField(
                placeholder,
                text: Binding(
                    get: { text.wrappedValue },
                    set: {
                        text.wrappedValue = $0
                        onQueryChanged($0, field)
                    }
                )
            )
            .focused($focusedField, equals: field)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .foregroundStyle(RouteTheme.primaryText)
            .tint(RouteTheme.accent)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(RouteTheme.accent)
                    .accessibilityHidden(true)
            }

            if field == .start {
                Button(action: useCurrentLocation) {
                    Group {
                        if isLocating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                                .foregroundStyle(RouteTheme.primaryText)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(isLocating)
                .accessibilityLabel("Use current location")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(RouteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    focusedField == field
                        ? RouteTheme.accent
                        : .clear,
                    lineWidth: 1.5
                )
        }
    }

    @ViewBuilder
    private func searchResultsView(
        for field: RouteLocationField
    ) -> some View {
        if activeField == field {
            if isSearching {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching places...")
                        .font(.subheadline)
                        .foregroundStyle(RouteTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
            } else if !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults, id: \.self) { location in
                        Button {
                            onSelect(location, field)
                            focusedField = nil
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin")
                                    .foregroundStyle(RouteTheme.accent)

                                Text(location.name)
                                    .font(.subheadline)
                                    .foregroundStyle(RouteTheme.primaryText)
                                    .lineLimit(2)

                                Spacer(minLength: 8)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 46)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if location != searchResults.last {
                            Divider()
                                .overlay(RouteTheme.border)
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(RouteTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(RouteTheme.border)
                }
            } else if let searchMessage {
                Text(searchMessage)
                    .font(.subheadline)
                    .foregroundStyle(RouteTheme.secondaryText)
                    .padding(.horizontal, 16)
            }
        }
    }

    private func useCurrentLocation() {
        focusedField = nil
        onUseCurrentLocation()
    }

    private func swapLocations() {
        focusedField = nil
        onSwap()
    }
}

#Preview {
    @Previewable @State var startText = "Apple Park"
    @Previewable @State var finishText = ""

    WaypointInputView(
        startText: $startText,
        finishText: $finishText,
        showsFinish: true,
        selectedStart: Route.preview.startLocation,
        selectedFinish: nil,
        searchResults: [Route.preview.finishLocation].compactMap { $0 },
        activeField: .finish,
        searchMessage: nil,
        isSearching: false,
        isLocating: false,
        onQueryChanged: { _, _ in },
        onFocus: { _ in },
        onSelect: { _, _ in },
        onUseCurrentLocation: {},
        onSwap: {}
    )
    .padding()
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
