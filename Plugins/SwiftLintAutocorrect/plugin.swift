import Foundation
import PackagePlugin

@main
struct SwiftLintFixPlugin: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        let executable = URL(fileURLWithPath: try context.tool(named: "swiftlint").path.string)
        for target in context.package.targets.compactMap({ $0 as? SourceModuleTarget }) {
            let process = Process()
            process.executableURL = executable
            process.arguments = [
                "--fix",
                target.directory.string
            ]

            try process.run()
            process.waitUntilExit()

            if process.terminationReason == .exit && process.terminationStatus == 0 {
                Diagnostics.remark("SwiftLint formatted \(target.directory)")
            }
            else {
                let problem = "\(process.terminationReason):\(process.terminationStatus)"
                Diagnostics.error("swift-lint --fix \(target.directory.stem) invocation failed: \(problem)")
            }
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
extension SwiftLintFixPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        Diagnostics.remark("Command plugin execution for Xcode project \(context.xcodeProject.displayName)")
    }
}
#endif
