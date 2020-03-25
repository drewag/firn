import Core

public protocol Expression: SQLConvertible {
//    let components: [SQLConvertible]
//
//    var sql: String {
//        return self.components.spaceSeparated
//    }
}

extension KeyPath: SQLConvertible where Root: Table {
    public var sql: String {
        guard let reflectable = Self.rootType as? AnyReflectable.Type else {
            fatalError("`\(Self.rootType)` is not `Reflectable`.")
        }
        guard let property = try! reflectable.anyReflectProperty(valueType: Self.valueType, keyPath: self) else {
            fatalError("Could not reflect property `\(self)`.")
        }
        print(property.path)
        return "\(Root.tableName)"
    }
}

extension KeyPath: Expression where Root: Table {

}

extension Int: Expression {
    public var sql: String {
        return "\(self)"
    }
}
