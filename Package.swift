// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "GameCatalogModules",
    defaultLocalization: "id",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "GameCatalogDomain", targets: ["GameCatalogDomain"]),
        .library(name: "GameCatalogData", targets: ["GameCatalogData"]),
        .library(name: "Common", targets: ["Common"]),
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
        .library(name: "DetailFeature", targets: ["DetailFeature"]),
        .library(name: "FavoriteFeature", targets: ["FavoriteFeature"]),
        .library(name: "AboutFeature", targets: ["AboutFeature"])
    ],
    targets: [
        .target(name: "GameCatalogDomain"),
        .target(name: "GameCatalogData", dependencies: ["GameCatalogDomain"]),
        .target(
            name: "Common",
            dependencies: ["GameCatalogDomain"],
            resources: [.process("Resources")]
        ),
        .target(name: "HomeFeature", dependencies: ["GameCatalogDomain", "Common"]),
        .target(name: "DetailFeature", dependencies: ["GameCatalogDomain", "Common"]),
        .target(name: "FavoriteFeature", dependencies: ["GameCatalogDomain", "Common"]),
        .target(name: "AboutFeature", dependencies: ["GameCatalogDomain", "Common"])
    ]
)
