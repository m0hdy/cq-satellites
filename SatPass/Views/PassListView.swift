import SwiftUI

/// Main screen — list of upcoming satellite passes.
struct PassListView: View {
    @Environment(SatelliteStore.self) private var store
    @State private var viewModel = PassListViewModel()

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
            .safeAreaInset(edge: .bottom) {
                if let description = viewModel.locationDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.bar)
                }
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
}
