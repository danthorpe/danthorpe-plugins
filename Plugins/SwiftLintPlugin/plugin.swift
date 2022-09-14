import Foundation
import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }
        if let isCi = ProcessInfo().environment["CI"], isCi == "TRUE" {
            return []
        }
        let tool = try context.tool(named: "swiftlint")
        return [
            .prebuildCommand(
                displayName: "Linting \(target.name)",
                executable: tool.path,
                arguments: [
                    "lint",
                    target.directory.string
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
