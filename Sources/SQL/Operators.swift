//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/1/20.
//

protocol AnyOperator: SQLConvertible {}

enum ArithmeticOperator: AnyOperator {
    case add, subtract, multiply, divide
    case modulus, exponentiation, squareRoot, cubeRoot, factorial

    var sql: String {
        switch self {
        case .add:
            return "+"
        case .subtract:
            return "-"
        case .multiply:
            return "*"
        case .divide:
            return "/"
        case .modulus:
            return "%"
        case .exponentiation:
            return "^"
        case .squareRoot:
            return "|/"
        case .cubeRoot:
            return "||/"
        case .factorial:
            return "!"
        }
    }
}

enum ComparisionOperator: AnyOperator {
    case equal, notEqual
    case lessThan, greaterThan, lessThanOrEqual, greaterThanOrEqual

    var sql: String {
        switch self {
        case .equal:
            return "=="
        case .notEqual:
            return "<>"
        case .lessThan:
            return "<"
        case .greaterThan:
            return ">"
        case .lessThanOrEqual:
            return "<="
        case .greaterThanOrEqual:
            return ">="
        }
    }
}

enum LogicalOperators: AnyOperator {
    case and, not, or

    var sql: String {
        switch self {
        case .and:
            return "AND"
        case .not:
            return "NOT"
        case .or:
            return "OR"
        }
    }
}

enum BitStringOperators: AnyOperator {
    case and, or, xor
    case onesCompliment
    case leftShift, rightShift

    var sql: String {
        switch self {
        case .and:
            return "&"
        case .or:
            return "|"
        case .xor:
            return "#"
        case .onesCompliment:
            return "~"
        case .leftShift:
            return "<<"
        case .rightShift:
            return ">>"
        }
    }
}
