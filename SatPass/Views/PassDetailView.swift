import SwiftUI

/// Detail view for a single satellite pass.
/// Hierarchy: countdown → compass → direction → supporting details.
/// Designed for a ham radio operator who needs to know WHEN and WHERE instantly.
struct PassDetailView: View {
    let pass: SatellitePass
    @State private var viewModel: PassDetailViewModel
    @State private var headingService = HeadingService()

    init(pass: SatellitePass) {
        self.pass = pass
        self._viewModel = State(initialValue: PassDetailViewModel(pass: pass))
    }

    var body: some View {
        List {
            // MARK: - Hero: Countdown (the single most important element)
            Section {
                CountdownView(pass: pass)
            }
            .listRowBackground(Color.clear)

            // MARK: - Compass: Where to point the antenna
            Section {
                VStack(spacing: 4) {
                    AzimuthView(
                        aosAzimuth: pass.aosAzimuth,
                        losAzimuth: pass.losAzimuth,
                        heading: headingService.heading
                    )
                    .frame(maxWidth: .infinity)

                    // Direction descriptions
                    HStack {
                        Label {
                            Text(viewModel.aosDescription)
                                .font(.caption)
                        } icon: {
                            Circle().fill(.green).frame(width: 8, height: 8)
                        }

                        Spacer()

                        Label {
                            Text(viewModel.losDescription)
                                .font(.caption)
                        } icon: {
                            Circle().fill(.red).frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } header: {
                Text("Antenna Direction")
            }

            // MARK: - Pass Quality & Key Stats
            Section("Pass Info") {
                LabeledContent("Satellite", value: pass.satelliteName)
                LabeledContent("NORAD ID", value: pass.noradID)

                LabeledContent("Max Elevation") {
                    HStack(spacing: 6) {
                        Text(viewModel.maxElevationFormatted)
                        SignalBars(filled: viewModel.quality.bars)
                        Text(viewModel.quality.label)
                            .font(.caption)
                            .foregroundStyle(viewModel.quality.color)
                    }
                }

                LabeledContent("Duration", value: viewModel.durationFormatted)
                LabeledContent("Direction", value: viewModel.directionSummary)
            }

            // MARK: - Radio: Frequencies & Modes
            Section("Radio") {
                if viewModel.frequencies.isEmpty {
                    Text("No frequency data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(viewModel.frequencies.enumerated()), id: \.offset) { _, freq in
                        FrequencyEntryView(frequency: freq)
                    }
                }
            }

            // MARK: - Timing
            Section("Timing") {
                LabeledContent("AOS") {
                    Text(pass.aos.formatted(date: .omitted, time: .standard))
                        .monospacedDigit()
                }
                LabeledContent("TCA") {
                    Text(pass.tca.formatted(date: .omitted, time: .standard))
                        .monospacedDigit()
                }
                LabeledContent("LOS") {
                    Text(pass.los.formatted(date: .omitted, time: .standard))
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle(pass.satelliteName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            headingService.startUpdating()
        }
        .onDisappear {
            headingService.stopUpdating()
        }
    }
}

// MARK: - Signal Bars

/// Mini signal-strength indicator (like cell bars) for pass quality.
private struct SignalBars: View {
    let filled: Int
    private let totalBars = 4

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<totalBars, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < filled ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
        }
        .frame(height: 16, alignment: .bottom)
    }
}

// MARK: - Frequency Entry

/// A single satellite frequency entry showing mode, downlink, uplink, beacon, and description.
/// Downlink is most prominent — that's what ham operators tune their receiver to.
private struct FrequencyEntryView: View {
    let frequency: SatelliteFrequency

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode badge + description on the same line
            HStack(spacing: 8) {
                ModeBadge(mode: frequency.mode)

                if let description = frequency.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Downlink (primary — what you tune your radio to)
            if let downlink = frequency.downlink {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .frame(width: 16)
                    Text("RX")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(downlink)
                        .font(.body.monospacedDigit().bold())
                }
            }

            // Uplink (secondary — what you transmit on)
            if let uplink = frequency.uplink {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .frame(width: 16)
                    Text("TX")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(uplink)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            // Beacon (if present)
            if let beacon = frequency.beacon {
                HStack(spacing: 6) {
                    Image(systemName: "wave.3.right")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                        .frame(width: 16)
                    Text("BCN")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(beacon)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mode Badge

/// Colored capsule showing the radio mode (FM, CW, SSB, etc.).
/// Mode determines radio setup: FM = easy, SSB/CW = need doppler tracking.
private struct ModeBadge: View {
    let mode: String

    var body: some View {
        Text(mode)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(modeColor.opacity(0.2))
            .foregroundStyle(modeColor)
            .clipShape(Capsule())
    }

    private var modeColor: Color {
        switch mode.uppercased() {
        case "FM": .green
        case "CW": .orange
        case "SSB": .blue
        case _ where mode.lowercased().contains("linear"): .purple
        default: .indigo
        }
    }
}
