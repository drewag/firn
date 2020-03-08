//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

struct SelectQuery: SQLConvertible {
    var distinct: Bool = false
    var selections: [Expression] = []
    var from: [FromItem] = []
    var `where`: SQLConvertible?
    var groupBy: [GroupingElement] = []
    var having: [SQLConvertible] = []
    var orderBy: Expression?
    var order: Order?
    var limit: Int?
    var offset: Int?

    var sql: String {
        var output = "SELECT"

        if distinct {
            output += " DISTINCT"
        }

        if self.selections.isEmpty {
            output += " *"
        }
        else {
            output += " " + self.selections.commaSeparated
        }

        if !self.from.isEmpty {
            output += " FROM " + self.from.map({$0.sql}).joined(separator: ", ")
        }

        if let `where` = self.where {
            output += " WHERE " + `where`.sql
        }

        if !self.groupBy.isEmpty {
            output += " GROUP BY " + self.groupBy.commaSeparated
        }

        if !self.having.isEmpty {
            output += " HAVING " + self.having.commaSeparated
        }

        if let orderBy = self.orderBy {
            output += " ORDER BY " + orderBy.sql

            if let order = self.order {
                output += " " + order.sql
            }
        }

        if let limit = self.limit {
            output += "LIMIT \(limit)"
        }

        if let offset = self.offset {
            output += "OFFSET \(offset)"
        }

        return output
    }
}
