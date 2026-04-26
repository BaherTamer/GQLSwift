//
//  main.swift
//  GQLSwift
//
//  GQLMain is a small command-line tool invoked by the Xcode “GQLPlugin” build
//  step (and usable manually) to walk a directory of `.graphql` / `.gql` files
//  and emit one generated Swift file (`GQLOperations`) via `GQLGenerator`.
//

import Foundation
import GQLGenerator

// MARK: - Command-line flags

/// Parses `argv` into a `GQLConfig` the generator understands.
private enum GQLMain {

    // MARK: Parse

    static func parsedConfig(
        from args: [String]
    ) throws -> GQLConfig {
        var i = 0
        var searchRoot: URL?
        var output: URL?
        var applyDefaultPathSkips = true

        // Walk tokens. Options that take a value (`--x path`) read the next token.
        while i < args.count {
            let token = args[i]
            
            switch token {
            case "--search-root":
                i += 1
                guard i < args.count else {
                    throw ParseError.missingValue(for: "--search-root")
                }
                searchRoot = url(
                    forPath: args[i],
                    isDirectory: true
                )
                
            case "--output":
                i += 1
                guard i < args.count else {
                    throw ParseError.missingValue(for: "--output")
                }
                output = url(
                    forPath: args[i],
                    isDirectory: false
                )
                
            case "--no-default-skips":
                // Set `GQLConfig.applyDefaultPathSkips` to `false` (it defaults to
                // `true`); the generator threads this into `GQLScanner.getGraphQLPaths`.
                applyDefaultPathSkips = false
                
            case "--help", "-h":
                helpText()
                // Process exit: success, no code generation.
                exit(EXIT_SUCCESS)
                
            case "--":
                // Common convention: everything after `--` is passthrough. We do
                // not have positional args yet; skip the token and continue.
                break
                
            default:
                throw ParseError.unknownArgument(token)
            }
            
            i += 1
        }

        guard
            let root = searchRoot,
            let out = output
        else {
            throw ParseError.missingOptions
        }

        return GQLConfig(
            searchRoot: root,
            outputFile: out,
            applyDefaultPathSkips: applyDefaultPathSkips
        )
    }

    // MARK: Helpers

    private static func url(
        forPath path: String,
        isDirectory: Bool
    ) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        return URL(
            fileURLWithPath: expanded,
            isDirectory: isDirectory
        )
    }

    /// Prints usage to stdout. The caller should then exit the process.
    private static func helpText() {
        print(
            """
            Usage: GQLMain --search-root <dir> --output <file.swift> [--no-default-skips]
            """
        )
    }
}

// MARK: - Parse errors

private enum ParseError: LocalizedError {
    case missingValue(for: String)
    case missingOptions
    case unknownArgument(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let flag):
            return "\(flag) requires a path"
        case .missingOptions:
            return "Missing --search-root or --output. Use --help."
        case .unknownArgument(let a):
            return "Unknown argument: \(a)"
        }
    }
}

// MARK: - Entry

// SwiftPM `executableTarget` uses this file’s top-level `do` as the process
// entry; it must appear after all types in this file. We parse argv, build
// `GQLConfig`, and call `GQLGenerator.generate`.

do {
    let config = try GQLMain.parsedConfig(
        from: Array(CommandLine.arguments.dropFirst())
    )
    try GQLGenerator.generate(configuration: config)
} catch {
    if
        let e = error as? LocalizedError,
        let m = e.errorDescription
    {
        fputs("\(m)\n", stderr)
    } else {
        fputs("\(error.localizedDescription)\n", stderr)
    }
    
    exit(EXIT_FAILURE)
}
