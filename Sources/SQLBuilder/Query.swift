//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

enum FromItem: SQLConvertible {
    case table(String)

    var sql: String {
        switch self {
        case .table(let table):
            return table
        }
    }
}

struct Function {
    let name: String
    let arguments: [Expression]
}

enum Order: SQLConvertible {
    case ascending
    case descending

    var sql: String {
        switch self {
        case .ascending:
            return "ASC"
        case .descending:
            return "DESC"
        }
    }
}
