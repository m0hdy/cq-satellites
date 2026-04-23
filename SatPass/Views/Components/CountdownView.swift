import SwiftUI

/// Live countdown to AOS or time remaining during a pass.
/// Self-contained: uses TimelineView for 1-second updates.
struct CountdownView: View {
    let pass: SatellitePass

    var body: some View {
        TimelineView(.periodic(from: .now, by: Constants.Timing.countdownInterval)) { context in
            countdownContent(at: context.date)
        }
    }

    @ViewBuilder
    private func countdownContent(at now: Date) -> some View {
        VStack(spacing: 6) {
            if pass.isActive(at: now) {
                // --- Active pass: show time remaining ---
                Label("OVERHEAD", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption.bold())
                    .foregroundStyle(.green)

                Text(Formatters.timeRemaining(pass.timeRemaining(from: now)))
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())

                Text("remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else if pass.isUpcoming(at: now) {
                // --- Upcoming pass: T-minus countdown ---
                Text("NEXT PASS")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text(Formatters.tCountdown(pass.timeUntilAOS(from: now)))
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .contentTransition(.numericText())

                Text(pass.aos.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else {
                // --- Completed pass ---
                Text("PASS COMPLETE")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
