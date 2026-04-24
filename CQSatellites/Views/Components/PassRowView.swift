import SwiftUI

/// A single row in the pass list. Designed for instant glanceability —
/// countdown and direction are the two things a ham radio op needs fastest.
struct PassRowView: View {
    let pass: SatellitePass
    @State private var now = Date.now

    private let timer = Timer.publish(
        every: Constants.Timing.countdownInterval,
        on: .main,
        in: .common
    ).autoconnect()

    private var isActive: Bool { pass.isActive(at: now) }

    var body: some View {
        HStack(spacing: 12) {
            // Active pass indicator — colored bar on the left edge
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? .green : .clear)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                // Top row: satellite name + max elevation
                HStack(alignment: .firstTextBaseline) {
                    Text(pass.satelliteName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(Formatters.degreesWhole(pass.maxElevation))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text("max el")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Bottom row: time info + direction
                HStack {
                    if isActive {
                        Label("LIVE", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                        Text(Formatters.timeRemaining(pass.timeRemaining(from: now)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.green.opacity(0.8))
                    } else if pass.isUpcoming(at: now) {
                        Text(Formatters.relativePassTime(pass.aos, from: now))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text(Formatters.passDirection(aos: pass.aosAzimuth, los: pass.losAzimuth))
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .onReceive(timer) { time in
            now = time
        }
    }
}
