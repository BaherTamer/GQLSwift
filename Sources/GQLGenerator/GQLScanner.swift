//
//  GQLScanner.swift
//  GraphQLOperationsGenerator
//
//  Created by Baher Tamer on 17/04/2026.
//

import Foundation

package enum GQLScanner {
    package static func getGraphQLPaths(
        searchRoot: URL,
        applyDefaultSkips: Bool
    ) throws -> [URL] {
        var urls: [URL] = []
        let enumerator = FileManager.default.enumerator(
            at: searchRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        
        while let item = enumerator?.nextObject() as? URL {
            if item.pathExtension.lowercased() == Constants.pathExtension {
                urls.append(item)
            }
        }

        return urls.sorted { $0.path < $1.path }
    }

    package static func readAndClean(file: URL) throws -> String {
        guard
            let data = try? Data(contentsOf: file),
            let text = String(data: data, encoding: .utf8)
        else {
            throw GQLError.cannotReadFile(file)
        }

        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                String(line)
                    .replacingOccurrences(
                        of: #"#[^\n]*"#,
                        with: "",
                        options: .regularExpression
                    )
                    .replacingOccurrences(
                        of: #"\s+$"#,
                        with: "",
                        options: .regularExpression
                    )
            }
            .joined(separator: "\n")
    }

    package static func write(_ content: String, to url: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            try content.write(
                to: url,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            throw GQLError.cannotCreateOutput(url)
        }
    }
}
