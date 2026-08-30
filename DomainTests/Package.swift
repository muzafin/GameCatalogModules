// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "GameCatalogDomainTests",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .testTarget(
            name: "GameCatalogDomainTests",
            dependencies: [
                .product(name: "GameCatalogDomain", package: "GameCatalogModules")
            ]
        )
    ]
)
