//
//  GQLConfig.swift
//  GQLSwift
//
//  Created by Baher Tamer on 17/04/2026.
//

import Foundation

package struct GQLConfig: Sendable {
    package let searchRoot: URL
    package let outputFile: URL
    package let applyDefaultPathSkips: Bool
    
    package init(
        searchRoot: URL,
        outputFile: URL,
        applyDefaultPathSkips: Bool
    ) {
        self.searchRoot = searchRoot
        self.outputFile = outputFile
        self.applyDefaultPathSkips = applyDefaultPathSkips
    }
}
