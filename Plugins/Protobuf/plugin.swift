import Foundation
import PackagePlugin

// Inspired by the official plugins from
// https://github.com/apple/swift-protobuf
// http://github.com/grpc/grpc-swift

@main
struct SwiftProtobuf {
    enum PluginError: Error {
        case invalidInputFileExtension
    }

    struct Configuration: Codable {
        struct Invocation: Codable {
            var protoFilesDirectory: String?
            var protoFiles: [String]
            var moduleMapping: String?
            var protobufOptions: [String]?
            var gRPCOptions: [String]?
        }
        var protocPath: String?
        var invocations: [Invocation]
    }

    static let configurationFilename = "protobuf-options.json"
    static let decoder = JSONDecoder()
}

extension SwiftProtobuf: BuildToolPlugin {
    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        // Find the configuration file
        let configuration = try readConfigurationFile(for: target)

        try validate(configuration)

        // Determine the path of protoc
        let protocPath: Path
        if let configuredProtocPath = configuration.protocPath {
            protocPath = Path(configuredProtocPath)
        } else if let environmentPath = ProcessInfo.processInfo.environment["PROTOC_PATH"] {
            protocPath = Path(environmentPath)
        } else {
            // See if SPM can find a binary for us
            protocPath = try context.tool(named: "protoc").path
        }

        let protocGenSwiftPath = try context.tool(named: "protoc-gen-swift").path
        let protocGenGRPCSwiftPath = try context.tool(named: "protoc-gen-grpc-swift").path

        // This plugin generates its output into GeneratedSources
        let outputDirectory = context.pluginWorkDirectory

        return configuration.invocations.map { invocation in
            invoke(
                target: target,
                invocation: invocation,
                protocPath: protocPath,
                protocGenSwiftPath: protocGenSwiftPath,
                protocGenGRPCSwiftPath: protocGenGRPCSwiftPath,
                outputDirectory: outputDirectory
            )
        }
    }
}

// MARK: - Helpers

private extension SwiftProtobuf {
    func readConfigurationFile(for target: SourceModuleTarget) throws -> Configuration {
        let configurationFilePath = target.directory.appending(
            subpath: Self.configurationFilename
        )
        let data = try Data(contentsOf: URL(fileURLWithPath: configurationFilePath.string))
        return try Self.decoder.decode(Configuration.self, from: data)
    }

    func validate(_ configuration: Configuration) throws {
        for invocation in configuration.invocations {
            for protoFile in invocation.protoFiles {
                if !protoFile.hasSuffix(".proto") {
                    throw PluginError.invalidInputFileExtension
                }
            }
        }
    }

    func invoke(
        target: Target,
        invocation: Configuration.Invocation,
        protocPath: Path,
        protocGenSwiftPath: Path,
        protocGenGRPCSwiftPath: Path,
        outputDirectory: Path
    ) -> Command {
        // Figure out the directory
        var directory = target.directory

        if var protoFilesDirectory = invocation.protoFilesDirectory {
            while protoFilesDirectory.hasPrefix("../") {
                directory = directory.removingLastComponent()
                protoFilesDirectory.removeFirst(3)
            }
            directory = directory.appending(subpath: protoFilesDirectory)
        }

        let hasProtobuf = invocation.protobufOptions != nil
        let hasGRPC = invocation.gRPCOptions != nil
        let moduleMappingFile = invocation.moduleMapping.map {
            target.directory.appending([$0]).string
        }

        // Construct the `protoc` arguments.
        var protocArgs: [String] = []

        if hasProtobuf {
            protocArgs.append(contentsOf: [
                "--plugin=protoc-gen-swift=\(protocGenSwiftPath)",
                "--swift_out=\(outputDirectory)",
            ])
            if let moduleMappingFile {
                protocArgs.append("--swift_opt=ProtoPathModuleMappings=\(moduleMappingFile)")
            }
        }

        if hasGRPC {
            protocArgs.append(contentsOf: [
                "--plugin=protoc-gen-grpc-swift=\(protocGenGRPCSwiftPath)",
                "--grpc-swift_out=\(outputDirectory)",
            ])
            if let moduleMappingFile {
                protocArgs.append("--grpc-swift_opt=ProtoPathModuleMappings=\(moduleMappingFile)")
            }
        }

        protocArgs.append(contentsOf: [
            "-I",
            "\(directory)",
        ])

        for option in invocation.protobufOptions ?? [] {
            protocArgs.append("--swift_opt=\(option)")
        }

        for option in invocation.gRPCOptions ?? [] {
            protocArgs.append("--grpc-swift_opt=\(option)")
        }

        var inputFiles = [Path]()
        var outputFiles = [Path]()

        for file in invocation.protoFiles {
            // Append the file to the protoc args so that it is used for generating
            protocArgs.append("\(file)")
            inputFiles.append(directory.appending(file))

            // The name of the output file is based on the name of the input file.
            // We validated in the beginning that every file has the suffix of .proto
            // This means we can just drop the last 5 elements and append the new suffix
            let fileStem = Path(file).stem
            if hasProtobuf {
                let protobufFile = fileStem.appending(".pb.swift")
                outputFiles.append(outputDirectory.appending(protobufFile))
            }
            if hasGRPC {
                let gRPCFile = fileStem.appending(".grpc.swift")
                outputFiles.append(outputDirectory.appending(gRPCFile))
            }
        }

        return Command.buildCommand(
            displayName: "\(target.name): Generating swift files from proto files",
            executable: protocPath,
            arguments: protocArgs,
            inputFiles: inputFiles + [protocGenSwiftPath],
            outputFiles: outputFiles
        )
    }
}
