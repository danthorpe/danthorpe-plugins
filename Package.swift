// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "danthorpe-plugins",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .plugin(name: "SwiftLintPlugin", targets: ["SwiftLintPlugin"]),
        .plugin(name: "SwiftLint --Fix", targets: ["SwiftLintFixPlugin"]),
    ],
    targets: [
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.49.1/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "227258fdb2f920f8ce90d4f08d019e1b0db5a4ad2090afa012fd7c2c91716df3"
        ),
        .plugin(
            name: "SwiftLintPlugin",
            capability: .buildTool(),
            dependencies: [
                "SwiftLintBinary"
            ]
        ),
        .plugin(
            name: "SwiftLintFixPlugin",
            capability: .command(
                intent: .custom(
                    verb: "swiftlint fix",
                    description: "Invokes swiftlint --fix, which will fix all correctable violations."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "All correctable violations are fixed by SwiftLint.")
                ]
            ),
            dependencies: [
                "SwiftLintBinary"
            ]
        )

    ]
)
