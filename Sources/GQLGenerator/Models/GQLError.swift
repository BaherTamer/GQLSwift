//
//  GQLError.swift
//  GQLSwift
//
//  Created by Baher Tamer on 17/04/2026.
//

import Foundation

enum GQLError: LocalizedError {
    case cannotReadFile(URL)
    case cannotCreateOutput(URL)
}

extension GQLError {
    var errorDescription: String? {
        switch self {
        case .cannotReadFile(let url):
            "Failed to read: \(url.lastPathComponent)"
        case .cannotCreateOutput(let url):
            "Failed to write: \(url.lastPathComponent)"
        }
    }
}
