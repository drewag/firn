//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

protocol SQLConvertible {
    var sql: String {get}
}

extension Array where Element: SQLConvertible {
    var commaSeparated: String {
        return self.map({$0.sql}).joined(separator: ", ")
    }

    var spaceSeparated: String {
        return self.map({$0.sql}).joined(separator: " ")
    }
}

extension Array where Element == SQLConvertible {
    var commaSeparated: String {
        return self.map({$0.sql}).joined(separator: ", ")
    }

    var spaceSeparated: String {
        return self.map({$0.sql}).joined(separator: " ")
    }
}
