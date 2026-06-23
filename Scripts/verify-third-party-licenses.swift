#!/usr/bin/env swift

import Foundation

struct ResolvedFile: Decodable {
    struct Pin: Decodable {
        let identity: String
        let location: String
    }

    let pins: [Pin]
}

struct ManifestFile: Decodable {
    struct Library: Decodable {
        let packageIdentity: String
        let name: String
        let license: String
        let repositoryURL: URL
        let licenseURL: URL
        let summary: String?
    }

    let libraries: [Library]
}

enum ScriptError: Error, CustomStringConvertible {
    case missingResolvedFile([String])
    case missingFile(String)
    case mismatch(missing: [String], stale: [String])

    var description: String {
        switch self {
        case .missingResolvedFile(let candidates):
            return "Missing Package.resolved. Searched: \(candidates.joined(separator: ", "))"
        case .missingFile(let path):
            return "Missing required file: \(path)"
        case .mismatch(let missing, let stale):
            var parts: [String] = []
            if !missing.isEmpty {
                parts.append("missing manifest entries: \(missing.joined(separator: ", "))")
            }
            if !stale.isEmpty {
                parts.append("stale manifest entries: \(stale.joined(separator: ", "))")
            }
            return parts.joined(separator: "; ")
        }
    }
}

func load<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(T.self, from: data)
}

func firstExistingURL(_ candidates: [URL]) -> URL? {
    for url in candidates where FileManager.default.fileExists(atPath: url.path) {
        return url
    }
    return nil
}

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let resolvedCandidates = [
    root.appendingPathComponent("Package.resolved"),
    root.appendingPathComponent("CQSatellites.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
    root.appendingPathComponent("CQSatellites.xcodeproj/project.xcworkspace/xcshareddata/Package.resolved"),
]
let manifestURL = root.appendingPathComponent("CQSatellites/Resources/ThirdPartyLicenses.json")

guard let resolvedURL = firstExistingURL(resolvedCandidates) else {
    throw ScriptError.missingResolvedFile(resolvedCandidates.map { $0.path })
}

guard fileManager.fileExists(atPath: manifestURL.path) else {
    throw ScriptError.missingFile(manifestURL.path)
}

let resolved = try load(ResolvedFile.self, from: resolvedURL)
let manifest = try load(ManifestFile.self, from: manifestURL)

let resolvedIdentities = Set(resolved.pins.map { $0.identity.lowercased() })
let manifestIdentities = Set(manifest.libraries.map { $0.packageIdentity.lowercased() })

let missing = resolvedIdentities.subtracting(manifestIdentities).sorted()
let stale = manifestIdentities.subtracting(resolvedIdentities).sorted()

guard missing.isEmpty && stale.isEmpty else {
    throw ScriptError.mismatch(missing: missing, stale: stale)
}

print("Third-party license inventory covers \(manifestIdentities.count) package(s).")
