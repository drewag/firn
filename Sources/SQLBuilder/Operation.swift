//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/10/20.
//

public struct Operation: SQLConvertible {
    enum Components {
        case left(Expression)
        case right(Expression)
        case both(Expression, Expression)
    }
    let components: Components
    let `operator`: AnyOperator

    public var sql: String {
        switch components {
        case .both(let lhs, let rhs):
            return "(\(lhs.sql) \(self.operator.sql) \(rhs.sql))"
        case .left(let lhs):
            return "(\(lhs.sql) \(self.operator.sql))"
        case .right(let rhs):
            return "(\(self.operator.sql) \(rhs.sql))"
        }
    }
}

// Arithmetic

public func + (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ArithmeticOperator.add)
}

public func - (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ArithmeticOperator.subtract)
}

public func * (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ArithmeticOperator.multiply)
}

public func / (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ArithmeticOperator.divide)
}

public func % (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ArithmeticOperator.modulus)
}

public func ^ (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ArithmeticOperator.exponentiation)
}

prefix operator |/
public prefix func |/ (rhs: Expression) -> Operation {
    return Operation(components: .right(rhs), operator: ArithmeticOperator.squareRoot)
}

prefix operator ||/
public prefix func ||/ (rhs: Expression) -> Operation {
    return Operation(components: .right(rhs), operator: ArithmeticOperator.cubeRoot)
}

// Comparisons

public func == (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ComparisionOperator.equal)
}

public func != (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ComparisionOperator.notEqual)
}

public func > (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ComparisionOperator.greaterThan)
}

public func >= (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ComparisionOperator.greaterThanOrEqual)
}

public func < (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ComparisionOperator.lessThan)
}

public func <= (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: ComparisionOperator.lessThanOrEqual)
}

// Logical

public func && (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: LogicalOperators.and)
}

public func || (lhs: Expression, rhs: Expression) -> Operation {
    return Operation(components: .both(lhs, rhs), operator: LogicalOperators.or)
}

public prefix func ! (rhs: Expression) -> Operation {
    return Operation(components: .right(rhs), operator: LogicalOperators.not)
}
