public protocol PathComponent {}
extension String: PathComponent {}

public enum Var: PathComponent, Hashable {
    case string, int
}


