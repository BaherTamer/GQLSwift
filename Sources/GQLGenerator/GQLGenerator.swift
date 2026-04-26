//
//  GQLGenerator.swift
//  GQLSwift
//
//  Created by Baher Tamer on 17/04/2026.
//

import Foundation

package enum GQLGenerator {
    package static func generate(configuration: GQLConfig) throws {
        let fileURLs = try GQLScanner.getGraphQLPaths(
            searchRoot: configuration.searchRoot,
            applyDefaultSkips: configuration.applyDefaultPathSkips
        )

        let processedFiles = try fileURLs.map {
            (
                path: $0.path,
                text: try GQLScanner.readAndClean(file: $0)
            )
        }

        var fragments: [String: GQLFragment] = [:]
        for file in processedFiles {
            GQLParser.parseFragments(
                in: file.text
            )
            .forEach {
                fragments[$0.name] = $0
            }
        }

        let operations = processedFiles.flatMap {
            GQLParser.parseOperations(
                in: $0.text,
                filePath: $0.path,
                fragments: fragments
            )
        }

        let structs = assignSwiftTypeNames(operations)
            .map {
                GQLFormatter.formatOperationStruct(
                    operation: $0.operation,
                    swiftTypeName: $0.swiftTypeName
                )
            }
            .joined(separator: "\n")

        let fileBody = "struct \(Constants.generatedStructName) {\n\(structs)\n}"
        try GQLScanner.write(fileBody, to: configuration.outputFile)
    }

    private static func assignSwiftTypeNames(
        _ operations: [GQLOperation]
    ) -> [(operation: GQLOperation, swiftTypeName: String)] {
        let tally = Dictionary(
            grouping: operations,
            by: \.name
        )
        .mapValues {
            $0.count
        }

        let sortedOps = operations.sorted {
            $0.name < $1.name ||
            (
                $0.name == $1.name &&
                $0.directory < $1.directory
            )
        }
        
        var usedNames = Set<String>()
        return sortedOps.map { op in
            let baseName = (
                tally[op.name, default: 0] > 1 ?
                "\(op.directory)\(op.name)" :
                op.name
            )
            
            var identifier = GQLFormatter.sanitize(baseName)
            var count = 2
            let original = identifier
            
            while usedNames.contains(identifier) {
                identifier = "\(original)\(count)"
                count += 1
            }

            usedNames.insert(identifier)
            return (op, identifier)
        }
    }
}
