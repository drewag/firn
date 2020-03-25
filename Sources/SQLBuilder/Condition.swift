//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/10/20.
//

public struct Condition: SQLConvertible {
    var criteria: [Expression]

    public var sql: String {
        return self.criteria.map({$0.sql}).joined(separator: " AND ")
    }
}
