// swift-tools-version: 5.7

import PackageDescription

var package = Package(name: "danthorpe-plugins")

package.dependencies = [
    .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.20.2"),
]

// MARK: - Names

let SwiftLint = "SwiftLint"
let SwiftLintBinary = "SwiftLintBinary"
let SwiftLintAutocorrect = "SwiftLintAutocorrect"
let Protobuf = "Protobuf"

// MARK: Products

package.products = [
    .plugin(name: SwiftLint, targets: [SwiftLint]),
    .plugin(name: SwiftLintAutocorrect, targets: [SwiftLintAutocorrect]),
    .plugin(name: Protobuf, targets: [Protobuf]),
]

// MARK: Targets

extension Target {

    static let swiftLintBinary: Target = .binaryTarget(
        name: SwiftLintBinary,
        url: "https://github.com/realm/SwiftLint/releases/download/0.49.1/SwiftLintBinary-macos.artifactbundle.zip",
        checksum: "227258fdb2f920f8ce90d4f08d019e1b0db5a4ad2090afa012fd7c2c91716df3"
    )

    static let swiftLint: Target = .plugin(
        name: SwiftLint,
        capability: .buildTool(),
        dependencies: [
            .swiftLintBinary
        ]
    )

    static let swiftLintAutocorrect: Target = .plugin(
        name: SwiftLintAutocorrect,
        capability: .buildTool(),
        dependencies: [
            .swiftLintBinary
        ]
    )

    static let protobuf: Target = .plugin(
        name: Protobuf,
        capability: .buildTool(),
        dependencies: [.protoc, .gRPC]
    )
}

package.targets = [
    .swiftLintBinary,
    .swiftLint,
    .swiftLintAutocorrect,
    .protobuf
]


// MARK: - Dependencies

extension Target.Dependency {
    static let swiftLintBinary: Target.Dependency = .target(
        name: SwiftLintBinary
    )
    static let protoc: Target.Dependency = .product(
        name: "protoc-gen-swift", package: "swift-protobuf"
    )
    static let gRPC: Target.Dependency = .product(
        name: "protoc-gen-grpc-swift", package: "grpc-swift"
    )
}
