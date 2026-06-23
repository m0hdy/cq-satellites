import Foundation

enum ThirdPartyLicenseCatalogError: LocalizedError {
    case missingManifest
    case emptyCatalog
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .missingManifest:
            return "Third-party license inventory could not be found in the app bundle."
        case .emptyCatalog:
            return "Third-party license inventory is empty."
        case .decodeFailed:
            return "Third-party license inventory could not be decoded."
        }
    }
}

struct ThirdPartyLicenseCatalog {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func load() throws -> ThirdPartyLicenseManifest {
        guard let url = bundle.url(forResource: "ThirdPartyLicenses", withExtension: "json") else {
            throw ThirdPartyLicenseCatalogError.missingManifest
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        do {
            let manifest = try decoder.decode(ThirdPartyLicenseManifest.self, from: data)
            guard !manifest.libraries.isEmpty else {
                throw ThirdPartyLicenseCatalogError.emptyCatalog
            }
            return manifest
        } catch let error as ThirdPartyLicenseCatalogError {
            throw error
        } catch {
            throw ThirdPartyLicenseCatalogError.decodeFailed
        }
    }
}
