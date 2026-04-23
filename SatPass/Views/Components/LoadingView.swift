import SwiftUI

/// Animated loading screen showing progress through startup phases.
struct LoadingView: View {
    let phase: LoadingPhase

    @State private var isOrbiting = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            orbitalAnimation

            phaseInfo

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                isOrbiting = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                pulseScale = 1.12
            }
        }
    }

    // MARK: - Orbital Animation

    private var orbitalAnimation: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1.5)
                .frame(width: 120, height: 120)

            Image(systemName: "globe.americas.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue.opacity(0.5))
                .scaleEffect(pulseScale)

            Image(systemName: phaseIcon)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .offset(y: -60)
                .rotationEffect(.degrees(isOrbiting ? 360 : 0))
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .locating: "location.fill"
        case .downloading: "arrow.down.circle.fill"
        case .parsing: "doc.text.magnifyingglass"
        case .predicting: "satellite.fill"
        case .error: "exclamationmark.triangle.fill"
        default: "satellite.fill"
        }
    }

    // MARK: - Phase Info

    private var phaseInfo: some View {
        VStack(spacing: 12) {
            Text(phaseTitle)
                .font(.headline)
                .animation(.easeInOut(duration: 0.3), value: phaseTitle)

            Text(phaseSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: phaseSubtitle)

            if case .predicting(let current, let total) = phase {
                ProgressView(value: Double(current), total: Double(total))
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(maxWidth: 220)
                    .padding(.top, 4)
            }

            if case .downloading = phase {
                ProgressView()
                    .controlSize(.small)
                    .padding(.top, 4)
            }
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .idle: "Preparing…"
        case .locating: "Finding Your Location"
        case .downloading: "Downloading Satellite Data"
        case .parsing(let count): "Found \(count) Satellites"
        case .predicting: "Computing Passes"
        case .complete: "Ready"
        case .error: "Something Went Wrong"
        }
    }

    private var phaseSubtitle: String {
        switch phase {
        case .idle: ""
        case .locating: "Requesting GPS coordinates…"
        case .downloading: "Fetching TLE data from CelesTrak…"
        case .parsing(let count): "Parsing orbital elements for \(count) satellites…"
        case .predicting(let current, let total): "\(current) of \(total) satellites processed"
        case .complete: ""
        case .error(let message): message
        }
    }
}
