//
//  GQLFormatter.swift
//  GraphQLOperationsGenerator
//
//  Created by Baher Tamer on 17/04/2026.
//

import Foundation

enum GQLFormatter {
    static func formatOperationStruct(
        operation: GQLOperation,
        swiftTypeName: String
    ) -> String {
        let trimmedDocument = operation.document.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let document = shouldPreserveLayout(trimmedDocument) ?
            trimmedDocument :
            prettyFormat(trimmedDocument)
        
        let indentation = "        "
        let indentedDocument = document
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { indentation + String($0) }
            .joined(separator: "\n")

        let name = operation.name.replacingOccurrences(of: "\"", with: "\\\"")
        let type = operation.type.replacingOccurrences(of: "\"", with: "\\\"")

        return """
            struct \(swiftTypeName) {
                static let name = "\(name)"
                static let type = "\(type)"
                static let document = \"\"\"
        \(indentedDocument)
                \"\"\"
            }
        
        """
    }

    static func sanitize(_ raw: String) -> String {
        guard let first = raw.first else { return "_Empty" }
        let head = (first.isLetter || first == "_") ? String(first) : "_"
        let tail = raw.dropFirst().map {
            ($0.isLetter || $0.isNumber || $0 == "_") ? $0 : Character("_")
        }
        return head + String(tail)
    }

    private static func shouldPreserveLayout(_ source: String) -> Bool {
        let lines = source.split(separator: "\n")
        guard lines.count >= 3 else { return false }
        return (lines.map(\.count).max() ?? 0) <= 200
    }

    private static func prettyFormat(_ source: String) -> String {
        var document: [Character] = []
        var depth = 0
        var index = source.startIndex
        var inString = false
        var escaped = false

        while index < source.endIndex {
            let char = source[index]
            
            if inString {
                document.append(char)
                
                if escaped {
                    escaped = false
                } else if char == "\\" {
                    escaped = true
                } else if char == "\"" {
                    inString = false
                }
                
                index = source.index(after: index)
                continue
            }

            switch char {
                
            case "\"":
                document.append(char)
                inString = true
                
            case "{":
                document.append(contentsOf: " {")
                depth += 1
                document.append("\n")
                let spaces = String(repeating: "  ", count: depth)
                document.append(contentsOf: spaces)
                
            case "}":
                depth = max(0, depth - 1)
                document.append("\n")
                let spaces = String(repeating: "  ", count: depth)
                document.append(contentsOf: spaces)
                document.append("}")
                
            case "(", ")", ",", ":":
                document.append(char)
                if char == ":" {
                    document.append(" ")
                }
                
            case " ", "\t", "\r", "\n":
                if
                    let last = document.last,
                    !last.isWhitespace,
                    last != "{",
                    last != "("
                {
                    document.append(" ")
                }
                
            default:
                document.append(char)
                
            }
            
            index = source.index(after: index)
        }
        
        return String(document)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
