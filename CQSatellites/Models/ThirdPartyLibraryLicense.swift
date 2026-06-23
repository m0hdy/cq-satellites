import Foundation

struct ThirdPartyLibraryLicense: Identifiable, Codable, Hashable {
    let packageIdentity: String
    let name: String
    let license: String
    let repositoryURL: URL
    let licenseURL: URL
    let summary: String?

    var id: String { packageIdentity }
}

struct ThirdPartyLicenseManifest: Codable {
    let generatedAt: String
    let libraries: [ThirdPartyLibraryLicense]
}
