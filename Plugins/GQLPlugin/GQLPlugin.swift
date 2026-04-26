//
//  GQLPlugin.swift
//  GQLSwift
//
//  Created by Baher Tamer on 17/04/2026.
//

import Foundation
import PackagePlugin

@main
struct GQLPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        let tool = try context.tool(named: Constants.toolName)
        let projectRoot = URL(
            fileURLWithPath: target.directory.string,
            isDirectory: true
        )
        
        return try GQLPluginCore.makeBuildCommands(
            toolPath: tool.path,
            pluginWorkDirectory: context.pluginWorkDirectory,
            projectRoot: projectRoot
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GQLPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let tool = try context.tool(named: Constants.toolName)
        let projectRoot = URL(
            fileURLWithPath: context.xcodeProject.directory.string,
            isDirectory: true
        )
        
        return try GQLPluginCore.makeBuildCommands(
            toolPath: tool.path,
            pluginWorkDirectory: context.pluginWorkDirectory,
            projectRoot: projectRoot
        )
    }
}
#endif

// MARK: - Build Command

private enum GQLPluginCore {
    static func makeBuildCommands(
        toolPath: Path,
        pluginWorkDirectory: Path,
        projectRoot: URL
    ) throws -> [Command] {
        let outputPath = pluginWorkDirectory.appending(Constants.generatedFileName)
        let inputFiles = getGraphQLPaths(projectRoot: projectRoot)
        
        return [
            .buildCommand(
                displayName: Constants.generatedDisplayName,
                executable: toolPath,
                arguments: [
                    "--search-root", projectRoot.path,
                    "--output", outputPath.string,
                ],
                inputFiles: inputFiles,
                outputFiles: [outputPath]
            ),
        ]
    }
    
    private static func getGraphQLPaths(projectRoot: URL) -> [Path] {
        var paths: [Path] = []
        let enumerator = FileManager.default.enumerator(
            at: projectRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        
        while let item = enumerator?.nextObject() as? URL {
            if item.pathExtension.lowercased() == Constants.pathExtension {
                paths.append(Path(item.path))
            }
        }
        
        return paths.sorted { $0.string < $1.string }
    }
}
