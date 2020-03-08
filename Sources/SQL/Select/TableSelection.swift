//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

extension Table {
    static func select(_ selections: [KeyPath<Self>]) -> SelectQueryBuilder {
        return SelectQueryBuilder(modifiers: [
            { $0.from = [.table(self.tableName)]}
        ])
    }
}
