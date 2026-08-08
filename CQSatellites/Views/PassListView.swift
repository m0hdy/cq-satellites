import SwiftUI

/// Main screen — list of upcoming satellite passes.
///
/// Rotating to landscape while on this screen activates AR mode showing
/// the next 5 upcoming satellites. If a detail view is pushed, landscape
/// AR is handled by PassDetailView instead.
struct PassListView: View {
    @Environment(SatelliteStore.self) private var store
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var viewModel = PassListViewModel()
    @State private var showFilterSheet = false
    @State private var showAbout = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        let filteredPasses = viewModel.filteredPasses(from: store.passes)
        let arPasses = Array(filteredPasses.prefix(Constants.AR.maxListTargets))

        NavigationStack(path: $navigationPath) {
            Group {
                if case .error(let message) = store.loadingPhase, store.passes.isEmpty {
                    ContentUnavailableView {
                        Label("Download Failed", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.retry(store: store) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if store.loadingPhase.isActive && store.passes.isEmpty {
                    LoadingView(phase: store.loadingPhase)
                } else if store.passes.isEmpty {
                    ContentUnavailableView(
                        "No Passes",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("No satellite passes found for your location.")
                    )
                } else if filteredPasses.isEmpty {
                    ContentUnavailableView(
                        "No Matching Passes",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try adjusting your filters to see more satellite passes.")
                    )
                } else {
                    List(filteredPasses) { pass in
                        NavigationLink(value: pass.id) {
                            PassRowView(pass: pass)
                        }
                    }
                    .refreshable {
                        await viewModel.refresh(store: store)
                    }
                }
            }
            .navigationTitle("CQ Satellites")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilterSheet.toggle()
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAbout.toggle()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .height(500), .large])
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationDestination(for: UUID.self) { passID in
                if let pass = store.passes.first(where: { $0.id == passID }) {
                    PassDetailView(pass: pass)
                }
            }
            .task {
                await viewModel.onAppear(store: store)
            }
        }
        #if os(iOS)
        .overlay {
            if verticalSizeClass == .compact && navigationPath.isEmpty && !arPasses.isEmpty {
                SatelliteARView(passes: arPasses)
                    .ignoresSafeArea()
            }
        }
        #endif
    }

    @ViewBuilder
    private var bottomBar: some View {
        HStack {
            if let description = viewModel.locationDescription {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(viewModel.satelliteFilterLabel) · \(viewModel.operatingModeFilterLabel) · \(viewModel.elevationFilterLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}

/// Bottom sheet for filtering passes by satellite type and minimum elevation.
private struct FilterSheet: View {
    @Bindable var viewModel: PassListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Satellite filter
                VStack(spacing: 8) {
                    Text("Satellites")
                        .font(.headline)

                    Text("Show only satellites with known amateur radio frequencies, or show all satellites in the catalog.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Picker("Satellites", selection: $viewModel.showOnlyWithFrequencies) {
                        Text("Amateur Radio").tag(true)
                        Text("Show All").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                Divider()

                // Operating mode filter
                VStack(spacing: 8) {
                    Text("Operating Modes")
                        .font(.headline)

                    Text("Show satellites that support any selected mode.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("Clear") {
                            viewModel.selectedOperatingModes.removeAll()
                        }
                        .disabled(viewModel.selectedOperatingModes.isEmpty)

                        Spacer()

                        Text(viewModel.operatingModeFilterLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    ForEach(OperatingMode.allCases) { mode in
                        Toggle(mode.rawValue, isOn: Binding(
                            get: { viewModel.selectedOperatingModes.contains(mode) },
                            set: { isSelected in
                                if isSelected {
                                    viewModel.selectedOperatingModes.insert(mode)
                                } else {
                                    viewModel.selectedOperatingModes.remove(mode)
                                }
                            }
                        ))
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Elevation filter
                VStack(spacing: 8) {
                    Text("Minimum Max Elevation")
                        .font(.headline)

                    Text("Hide passes below this peak elevation. Higher passes give stronger signals and less atmospheric interference.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Picker("Minimum Elevation", selection: $viewModel.minimumElevation) {
                        Text("All").tag(0.0)
                        Text("10°").tag(10.0)
                        Text("20°").tag(20.0)
                        Text("30°").tag(30.0)
                        Text("45°").tag(45.0)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
