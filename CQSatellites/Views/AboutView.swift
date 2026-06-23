import SwiftUI

/// About screen displaying app information, version, build number, and links.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var licenseManifestState: LicenseManifestState = .loading

    private enum LicenseManifestState {
        case loading
        case loaded(ThirdPartyLicenseManifest)
        case failed(String)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (Build \(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 12) {
                        Image("ISSIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)

                        Text("CQ Satellites")
                            .font(.title)
                            .fontWeight(.semibold)

                        Text("by M0HDY")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    // Information Section
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Version")
                                .font(.headline)
                            Text(appVersion)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            Text("CQ Satellites helps Amateur Radio (HAM) enthusiasts find upcoming satellite passes quickly and easily. Get real-time orbital predictions and never miss a transmission opportunity.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Links")
                                .font(.headline)

                            Link(destination: URL(string: "https://github.com/m0hdy/cq-satellites")!) {
                                HStack {
                                    Label("View on GitHub", systemImage: "link")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }

                            Link(destination: URL(string: "https://github.com/m0hdy/cq-satellites/issues")!) {
                                HStack {
                                    Label("Report an Issue", systemImage: "exclamationmark.circle")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }

                            Link(destination: URL(string: "https://github.com/m0hdy/cq-satellites/blob/main/LICENSE")!) {
                                HStack {
                                    Label("ISC License", systemImage: "doc.text")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Third-Party Licenses")
                                .font(.headline)

                            Text("This list is compiled from the bundled license inventory and verified against Package.resolved.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            licenseSection
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                loadLicenseManifest()
            }
        }
    }

    @ViewBuilder
    private var licenseSection: some View {
        switch licenseManifestState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .leading)
        case .failed(let message):
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .loaded(let manifest):
            VStack(alignment: .leading, spacing: 12) {
                Text("\(manifest.libraries.count) \(manifest.libraries.count == 1 ? "library" : "libraries")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(manifest.libraries) { library in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(library.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(library.license)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        if let summary = library.summary {
                            Text(summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Link("Repository", destination: library.repositoryURL)
                            Spacer()
                            Link("License", destination: library.licenseURL)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func loadLicenseManifest() {
        do {
            licenseManifestState = .loaded(try ThirdPartyLicenseCatalog().load())
        } catch {
            licenseManifestState = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    AboutView()
}
