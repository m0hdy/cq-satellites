import SwiftUI

/// Main screen — list of upcoming satellite passes.
struct PassListView: View {
    @Environment(SatelliteStore.self) private var store
    @State private var viewModel = PassListViewModel()
    @State private var showElevationPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.passes.isEmpty {
                    ProgressView("Computing passes…")
                } else if store.passes.isEmpty {
                    ContentUnavailableView(
                        "No Passes",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("No satellite passes found for your location.")
                    )
                } else {
                    List(viewModel.filteredPasses(from: store.passes)) { pass in
                        NavigationLink(value: pass.id) {
                            PassRowView(pass: pass)
                        }
                    }
                    .refreshable {
                        await viewModel.refresh(store: store)
                    }
                }
            }
            .navigationTitle("SatPass")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showElevationPicker.toggle()
                    } label: {
                        Label(viewModel.elevationFilterLabel, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showElevationPicker) {
                ElevationFilterSheet(viewModel: viewModel)
                    .presentationDetents([.height(260)])
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
            Text(viewModel.elevationFilterLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}

/// Bottom sheet for choosing minimum elevation.
private struct ElevationFilterSheet: View {
    @Bindable var viewModel: PassListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
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
