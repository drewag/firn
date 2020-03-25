//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

import Foundation
import Core

public protocol Table: Reflectable {}

extension Table {
    static var tableName: String {
        return "\(self)".camelCaseToSnakeCase
    }
}
