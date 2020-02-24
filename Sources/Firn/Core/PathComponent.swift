public protocol PathComponent {}
extension String: PathComponent {}

public struct Var: PathComponent, Hashable {
    enum Kind {
        case string, int
    }

    let name: String?
    let kind: Kind

    public static let string = Var(name: nil, kind: .string)
    public static let int = Var(name: nil, kind: .int)

    public static func string(named: String) -> Var {
        return Var(name: named, kind: .string)
    }

    public static func int(named: String) -> Var {
        return Var(name: named, kind: .int)
    }
}


