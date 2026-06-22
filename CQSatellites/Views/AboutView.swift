import SwiftUI

/// About screen displaying app information, version, build number, and links.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (Build \(build))"
    }

    var body: some View {
        NavigationStack {
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
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
