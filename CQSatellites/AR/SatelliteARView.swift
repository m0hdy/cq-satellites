#if os(iOS)
import SwiftUI
import RealityKit
import ARKit

/// Full-screen AR overlay showing satellite positions in the sky.
///
/// Uses ARKit world tracking with gravity+heading alignment so that
/// RealityKit entities are placed at the correct compass bearings and
/// elevations in the camera feed.
///
/// Supports two modes:
/// - **Single target** (from detail view): one satellite highlighted green.
/// - **Multi target** (from list view): up to 5 satellites highlighted green.
///
/// Activated automatically when the device rotates to landscape.
/// Rotate back to portrait to dismiss.
struct SatelliteARView: View {
    let passes: [SatellitePass]

    @Environment(SatelliteStore.self) private var store
    @State private var viewModel: SatelliteARViewModel
    @State private var locationService = LocationService()

    init(passes: [SatellitePass]) {
        self.passes = passes
        self._viewModel = State(initialValue: SatelliteARViewModel(targetPasses: passes))
    }

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            // MARK: - Overlay UI
            VStack {
                // Top bar - visible satellite count
                HStack {
                    Spacer()

                    if !viewModel.visibleSatellites.isEmpty {
                        Text("\(viewModel.visibleSatellites.count) other visible")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding()

                Spacer()

                // Bottom info panel
                if !viewModel.targetPositions.isEmpty {
                    TargetInfoPanel(targets: viewModel.targetPositions)
                }
            }

            // AR session error overlay
            if let error = viewModel.arSessionError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 120)
                }
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        .onAppear { startAR() }
        .onDisappear { viewModel.stopTracking() }
    }

    private func startAR() {
        Task {
            let station: GroundStation
            if let cached = locationService.groundStation {
                station = cached
            } else {
                do {
                    let location = try await locationService.getCurrentLocation()
                    station = GroundStation(location: location)
                } catch {
                    station = Constants.Defaults.londonStation
                }
            }
            viewModel.startTracking(satellites: store.satellites, observer: station)
        }
    }
}

// MARK: - AR View Container (UIViewRepresentable)

/// Wraps an `ARView` with world tracking aligned to gravity and magnetic heading.
/// Manages RealityKit entities that represent satellite markers.
@MainActor
private struct ARViewContainer: UIViewRepresentable {
    let viewModel: SatelliteARViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        let anchor = AnchorEntity(.world(transform: .init(diagonal: [1, 1, 1, 1])))
        arView.scene.addAnchor(anchor)
        context.coordinator.rootAnchor = anchor
        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if let error = context.coordinator.sessionError {
            viewModel.arSessionError = error
        }

        // Snapshot main-actor state before entering coordinator logic.
        let targetIDs = viewModel.targetNoradIDs
        let targetPositions = viewModel.targetPositions
        let visibleSatellites = viewModel.visibleSatellites

        context.coordinator.updateMarkers(
            targetIDs: targetIDs,
            targetPositions: targetPositions,
            visibleSatellites: visibleSatellites
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        var rootAnchor: AnchorEntity?
        var arView: ARView?
        var sessionError: String?

        /// Parent entity per satellite (sphere + label children).
        private var markerParents: [String: Entity] = [:]
        /// Label parent per satellite (for billboarding).
        private var labelParents: [String: Entity] = [:]
        /// Text mesh entity per satellite (for updating text).
        private var textEntities: [String: ModelEntity] = [:]
        /// Last rendered elevation per satellite (avoids recreating text mesh every frame).
        private var lastRenderedElevations: [String: Int] = [:]
        /// ISS icon wrapper entities (for billboarding the icon plane).
        private var iconEntities: [String: Entity] = [:]
        /// Cached ISS texture resource (loaded once from bundle).
        private var issTexture: TextureResource?

        // MARK: - Entity Management

        @MainActor
        func updateMarkers(
            targetIDs: Set<String>,
            targetPositions: [(pass: SatellitePass, position: SatellitePosition)],
            visibleSatellites: [(name: String, noradID: String, position: SatellitePosition)]
        ) {
            guard let anchor = rootAnchor else { return }

            var activeIDs = Set<String>()

            // All target satellites (green markers)
            for (pass, pos) in targetPositions {
                let id = pass.noradID
                activeIDs.insert(id)
                updateOrCreate(
                    id: id,
                    name: pass.satelliteName,
                    position: pos,
                    isTarget: true,
                    anchor: anchor
                )
            }

            // Other visible satellites (blue markers)
            for sat in visibleSatellites {
                activeIDs.insert(sat.noradID)
                if !targetIDs.contains(sat.noradID) {
                    updateOrCreate(
                        id: sat.noradID,
                        name: sat.name,
                        position: sat.position,
                        isTarget: false,
                        anchor: anchor
                    )
                }
            }

            // Remove stale markers
            for id in markerParents.keys where !activeIDs.contains(id) {
                markerParents[id]?.removeFromParent()
                markerParents.removeValue(forKey: id)
                labelParents.removeValue(forKey: id)
                textEntities.removeValue(forKey: id)
                lastRenderedElevations.removeValue(forKey: id)
                iconEntities.removeValue(forKey: id)
            }

            // Billboard all labels toward camera
            billboardAllLabels()
        }

        @MainActor
        private func updateOrCreate(
            id: String,
            name: String,
            position: SatellitePosition,
            isTarget: Bool,
            anchor: AnchorEntity
        ) {
            let worldPos = position.arDirection * Constants.AR.markerDistance
            let roundedElev = Int(position.elevation.rounded())

            if let parent = markerParents[id] {
                // Update position
                parent.position = SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)

                // Update text only when elevation visually changes
                if lastRenderedElevations[id] != roundedElev,
                   let textEntity = textEntities[id] {
                    let labelText = "\(name) \(roundedElev)°"
                    let fontSize: CGFloat = isTarget
                        ? Constants.AR.targetLabelFontSize
                        : Constants.AR.nonTargetLabelFontSize
                    let newMesh = MeshResource.generateText(
                        labelText,
                        extrusionDepth: 0.001,
                        font: .systemFont(ofSize: fontSize),
                        containerFrame: .zero,
                        alignment: .center,
                        lineBreakMode: .byTruncatingTail
                    )
                    textEntity.model?.mesh = newMesh
                    let bounds = newMesh.bounds
                    textEntity.position.x = -bounds.extents.x / 2
                    lastRenderedElevations[id] = roundedElev
                }
            } else {
                // Create new marker hierarchy
                let parent = Entity()
                parent.position = SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)

                let color: UIColor = isTarget ? .systemGreen : .systemBlue

                // ISS gets a custom icon plane; all others get spheres
                if id == Constants.AR.issNoradID, let texture = loadISSTexture() {
                    let planeSize = Constants.AR.issIconPlaneSize
                    var material = UnlitMaterial()
                    material.color = .init(tint: color, texture: .init(texture))
                    material.opacityThreshold = 0.05
                    let iconWrapper = Entity()
                    let plane = ModelEntity(
                        mesh: .generatePlane(width: planeSize, height: planeSize),
                        materials: [material]
                    )
                    iconWrapper.addChild(plane)
                    parent.addChild(iconWrapper)
                    iconEntities[id] = iconWrapper
                } else {
                    let radius: Float = isTarget
                        ? Constants.AR.targetSphereRadius
                        : Constants.AR.nonTargetSphereRadius
                    let sphere = ModelEntity(
                        mesh: .generateSphere(radius: radius),
                        materials: [SimpleMaterial(color: color, isMetallic: false)]
                    )
                    parent.addChild(sphere)
                }

                // Label parent (offset above marker, billboarded independently)
                let labelOffset: Float = isTarget
                    ? Constants.AR.targetLabelOffset
                    : Constants.AR.nonTargetLabelOffset
                let labelParent = Entity()
                labelParent.position = [0, labelOffset, 0]

                let labelText = "\(name) \(roundedElev)°"
                let fontSize: CGFloat = isTarget
                    ? Constants.AR.targetLabelFontSize
                    : Constants.AR.nonTargetLabelFontSize
                let textMesh = MeshResource.generateText(
                    labelText,
                    extrusionDepth: 0.001,
                    font: .systemFont(ofSize: fontSize),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byTruncatingTail
                )
                let textEntity = ModelEntity(
                    mesh: textMesh,
                    materials: [UnlitMaterial(color: .white)]
                )
                // Center text horizontally
                let bounds = textMesh.bounds
                textEntity.position.x = -bounds.extents.x / 2

                labelParent.addChild(textEntity)
                parent.addChild(labelParent)
                anchor.addChild(parent)

                markerParents[id] = parent
                labelParents[id] = labelParent
                textEntities[id] = textEntity
                lastRenderedElevations[id] = roundedElev
            }
        }

        @MainActor
        private func billboardAllLabels() {
            guard let arView,
                  let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
            let cameraPos = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            for (_, labelParent) in labelParents {
                let worldPos = labelParent.position(relativeTo: nil)
                labelParent.look(at: cameraPos, from: worldPos, relativeTo: nil)
                // Flip 180 degrees so text faces the camera (generateText faces +Z, look faces -Z)
                labelParent.orientation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
            }
            // Billboard ISS icon planes to always face the camera
            for (_, icon) in iconEntities {
                let worldPos = icon.position(relativeTo: nil)
                icon.look(at: cameraPos, from: worldPos, relativeTo: nil)
                icon.orientation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
            }
        }

        // MARK: - ISS Texture Loading

        @MainActor
        private func loadISSTexture() -> TextureResource? {
            if let cached = issTexture { return cached }
            guard let url = Bundle.module.url(forResource: "iss_icon", withExtension: "png")
                    ?? Bundle.main.url(forResource: "iss_icon", withExtension: "png") else {
                print("[AR] iss_icon.png not found in any bundle")
                return nil
            }
            do {
                let texture = try TextureResource.load(contentsOf: url)
                issTexture = texture
                return texture
            } catch {
                print("[AR] Failed to load ISS texture: \(error)")
                return nil
            }
        }

        // MARK: - ARSessionDelegate

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            Task { @MainActor [weak self] in
                self?.sessionError = error.localizedDescription
            }
        }

        nonisolated func sessionWasInterrupted(_ session: ARSession) {
            Task { @MainActor [weak self] in
                self?.sessionError = "AR session interrupted"
            }
        }

        nonisolated func sessionInterruptionEnded(_ session: ARSession) {
            Task { @MainActor [weak self] in
                self?.sessionError = nil
            }
        }
    }
}

// MARK: - Target Info Panel

/// Semi-transparent bottom panel showing target satellite telemetry.
/// Adapts between single-target (full detail) and multi-target (compact list) modes.
private struct TargetInfoPanel: View {
    let targets: [(pass: SatellitePass, position: SatellitePosition)]

    /// The primary target - highest elevation satellite for best visibility.
    private var primary: (pass: SatellitePass, position: SatellitePosition)? {
        targets.max(by: { $0.position.elevation < $1.position.elevation })
    }

    var body: some View {
        VStack(spacing: 8) {
            if targets.count == 1, let target = targets.first {
                singleTargetContent(name: target.pass.satelliteName, position: target.position)
            } else {
                multiTargetContent
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func singleTargetContent(name: String, position: SatellitePosition) -> some View {
        Text(name)
            .font(.headline)
            .foregroundStyle(.white)

        HStack(spacing: 16) {
            telemetryColumn(
                label: Formatters.compassDirection(position.azimuth),
                value: String(format: "%.1f°", position.azimuth)
            )
            Divider().frame(height: 30)
            telemetryColumn(
                label: "Elevation",
                value: String(format: "%.1f°", position.elevation)
            )
            Divider().frame(height: 30)
            telemetryColumn(
                label: "Distance",
                value: String(format: "%.0f km", position.distance)
            )
        }
        .foregroundStyle(.white)

        HStack(spacing: 4) {
            Circle()
                .fill(position.isVisible ? .green : .red)
                .frame(width: 8, height: 8)
            Text(position.isVisible ? "Above Horizon ✓" : "Below Horizon")
                .font(.caption)
                .foregroundStyle(position.isVisible ? Color.green : Color.red)
        }
    }

    @ViewBuilder
    private var multiTargetContent: some View {
        Text("Tracking \(targets.count) Satellites")
            .font(.headline)
            .foregroundStyle(.white)

        HStack(spacing: 12) {
            ForEach(targets, id: \.pass.id) { target in
                VStack(spacing: 4) {
                    Circle()
                        .fill(target.position.isVisible ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(target.pass.satelliteName)
                        .font(.caption2.bold())
                        .lineLimit(1)
                    Text(String(format: "%.0f°", target.position.elevation))
                        .font(.caption2.monospacedDigit())
                }
                .foregroundStyle(.white)
            }
        }
    }

    private func telemetryColumn(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption.bold())
            Text(value)
                .font(.caption2.monospacedDigit())
        }
    }
}

#else
// macOS fallback - ARKit is iOS-only
import SwiftUI

struct SatelliteARView: View {
    let passes: [SatellitePass]

    var body: some View {
        ContentUnavailableView(
            "AR View",
            systemImage: "arkit",
            description: Text("Augmented reality satellite tracking is only available on iOS.")
        )
    }
}
#endif
