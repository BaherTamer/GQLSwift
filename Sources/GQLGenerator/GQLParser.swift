//
//  GQLParser.swift
//  GQLSwift
//
//  Created by Baher Tamer on 22/04/2026.
//

import Foundation

enum GQLParser {
    static func parseFragments(in text: String) -> [GQLFragment] {
        guard
            let regex = try? NSRegularExpression(
                pattern: #"\bfragment\b"#,
                options: []
            )
        else { return [] }
        
        var results: [GQLFragment] = []
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            guard
                let range = Range(match.range, in: text),
                let frag = exportFragment(
                    text: text,
                    startingAt: range.lowerBound
                )
            else { continue }
            results.append(frag)
        }
        
        return Array(Set(results))
    }

    static func parseOperations(
        in text: String,
        filePath: String,
        fragments: [String: GQLFragment]
    ) -> [GQLOperation] {
        let parts = filePath.split(separator: "/").map(String.init)
        let directory = (
            parts.count >= 2 ?
            parts[parts.count - 2].replacingOccurrences(of: " ", with: "") :
            "Default"
        )

        var ops: [GQLOperation] = []
        let mutation = findOperations(
            type: "mutation",
            pattern: #"\bmutation\b"#,
            text: text,
            directory: directory
        )
        let query = findOperations(
            type: "query",
            pattern: #"\bquery \b"#,
            text: text,
            directory: directory
        )

        ops.append(contentsOf: mutation)
        ops.append(contentsOf: query)

        return ops.map { op in
            if op.dependencies.isEmpty {
                return op
            }
            
            let expandedContent = resolveDependencies(
                for: op.dependencies,
                available: fragments
            )
            
            return GQLOperation(
                name: op.name,
                type: op.type,
                document: op.document + "\n" + expandedContent,
                directory: op.directory,
                dependencies: op.dependencies
            )
        }
    }

    private static func findOperations(
        type: String,
        pattern: String,
        text: String,
        directory: String
    ) -> [GQLOperation] {
        guard
            let regex = try? NSRegularExpression(
                pattern: pattern,
                options: []
            )
        else { return [] }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        var out: [GQLOperation] = []
        
        for match in matches {
            guard
                let range = Range(match.range, in: text),
                let op = exportOperation(
                    type: type,
                    text: text,
                    start: range.lowerBound,
                    directory: directory
                )
            else { continue }
            
            out.append(op)
        }
        
        return out
    }

    private static func exportFragment(
        text: String,
        startingAt start: String.Index
    ) -> GQLFragment? {
        let afterKeyword = text.index(start, offsetBy: "fragment".count)
        let body = String(text[afterKeyword...])
        guard
            let braceIdx = body.firstIndex(of: "{")
        else { return nil }
        
        let name = body[..<braceIdx]
            .split(separator: " ")
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? ""

        var characters: [Character] = []
        var depth = -1
        
        for character in body[braceIdx...] {
            characters.append(character)
            
            if character == "{" {
                depth = (depth == -1) ? 1 : depth + 1
            } else if character == "}" {
                depth -= 1
            }
            
            if depth == 0 {
                let content = "fragment " + String(body[..<braceIdx]) + String(characters)
                let deps = fragmentSpreadNames(in: content)
                return GQLFragment(
                    name: name,
                    content: content,
                    dependencies: Array(Set(deps))
                )
            }
        }
        
        return nil
    }

    private static func exportOperation(
        type: String,
        text: String,
        start: String.Index,
        directory: String
    ) -> GQLOperation? {
        let afterOp = text.index(start, offsetBy: type.count)
        let body = String(text[afterOp...])
        
        guard
            let bracePos = body.firstIndex(of: "{")
        else { return nil }
        
        var nameEndIdx: String.Index = bracePos
        if let parenPos = body.firstIndex(of: "(") {
            let idxParen = body.distance(from: body.startIndex, to: parenPos)
            let idxBrace = body.distance(from: body.startIndex, to: bracePos)
            if idxParen < idxBrace {
                nameEndIdx = parenPos
            }
        }

        var opName = String(body[..<nameEndIdx]).trimmingCharacters(
            in: .whitespacesAndNewlines
        ) + type.capitalized
        
        opName = opName.replacingOccurrences(of: " ", with: "")
        
        if !opName.isEmpty {
            opName = String(
                opName.prefix(1).uppercased() + opName.dropFirst()
            )
        }

        var characters: [Character] = []
        var depth = -1
        
        for char in body[bracePos...] {
            characters.append(char)
            
            if char == "{" {
                depth = (depth == -1) ? 1 : depth + 1
            } else if char == "}" {
                depth -= 1
            }
            
            if depth == 0 {
                let document = type + " " + String(body[..<bracePos]).trimmingCharacters(
                    in: .whitespaces
                ) + String(characters)
                return GQLOperation(
                    name: opName,
                    type: type,
                    document: document,
                    directory: directory,
                    dependencies: Set(fragmentSpreadNames(in: document))
                )
            }
        }
        
        return nil
    }

    private static func fragmentSpreadNames(in text: String) -> [String] {
        let pattern = #"(?!\.\.\.on)(\.\.\.\w+)"#
        guard
            let regex = try? NSRegularExpression(
                pattern: pattern,
                options: []
            )
        else { return [] }
        
        let matches = regex.matches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text)
        )
        
        return matches.compactMap { m -> String? in
            guard
                let range = Range(m.range(at: 1), in: text)
            else { return nil }
            return String(text[range]).replacingOccurrences(of: "...", with: "")
        }
    }

    private static func resolveDependencies(
        for names: Set<String>,
        available: [String: GQLFragment]
    ) -> String {
        var seen = Set<String>()
        var output = ""
        
        func visit(_ name: String) {
            guard
                !seen.contains(name),
                let frag = available[name]
            else { return }
            seen.insert(name)
            output += frag.content + "\n"
            frag.dependencies.forEach { visit($0) }
        }
        
        names.forEach { visit($0) }
        return output
    }
}
