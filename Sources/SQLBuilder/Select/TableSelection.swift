//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

extension Table {
    public static func select() -> SelectQueryBuilder {
        return SelectQueryBuilder(modifiers: [
            { $0.from = [.table(self.tableName)] }
        ])
    }
}
