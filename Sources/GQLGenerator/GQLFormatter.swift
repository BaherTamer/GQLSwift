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
        let trimmedContent = operation.content.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let content = shouldPreserveLayout(trimmedContent) ?
            trimmedContent :
            prettyFormat(trimmedContent)
        
        let indentation = "        "
        let indentedContent = content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { indentation + String($0) }
            .joined(separator: "\n")

        let name = operation.name.replacingOccurrences(of: "\"", with: "\\\"")
        let type = operation.type.replacingOccurrences(of: "\"", with: "\\\"")

        return """
            struct \(swiftTypeName) {
                static let name = "\(name)"
                static let type = "\(type)"
                static let content = \"\"\"
        \(indentedContent)
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
        var content: [Character] = []
        var depth = 0
        var index = source.startIndex
        var inString = false
        var escaped = false

        while index < source.endIndex {
            let char = source[index]
            
            if inString {
                content.append(char)
                
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
                content.append(char)
                inString = true
                
            case "{":
                content.append(contentsOf: " {")
                depth += 1
                content.append("\n")
                let spaces = String(repeating: "  ", count: depth)
                content.append(contentsOf: spaces)
                
            case "}":
                depth = max(0, depth - 1)
                content.append("\n")
                let spaces = String(repeating: "  ", count: depth)
                content.append(contentsOf: spaces)
                content.append("}")
                
            case "(", ")", ",", ":":
                content.append(char)
                if char == ":" {
                    content.append(" ")
                }
                
            case " ", "\t", "\r", "\n":
                if
                    let last = content.last,
                    !last.isWhitespace,
                    last != "{",
                    last != "("
                {
                    content.append(" ")
                }
                
            default:
                content.append(char)
                
            }
            
            index = source.index(after: index)
        }
        
        return String(content)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
