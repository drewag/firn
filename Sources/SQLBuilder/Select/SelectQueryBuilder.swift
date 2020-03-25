//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

public struct SelectQueryBuilder {
    typealias Modifier = (inout SelectQuery) -> ()

    let modifiers: [Modifier]

    func appending(_ modifier: @escaping Modifier) -> SelectQueryBuilder {
        return SelectQueryBuilder(modifiers: self.modifiers + [modifier])
    }

    func generateQuery() -> SelectQuery {
        var query = SelectQuery()
        for modifier in self.modifiers {
            modifier(&query)
        }
        return query
    }
}

extension SelectQueryBuilder {
}
