import Foundation

enum InitializationError: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    case routeConflict
    case unrecognizedPathComponent

    var title: String {
        switch self {
        case .routeConflict:
            return "Route Conflict"
        case .unrecognizedPathComponent:
            return "Unrecognized Path Component"
        }
    }

    var reason: String {
        switch self {
        case .routeConflict:
            return "A route was declared that conflicts with a previous route."
        case .unrecognizedPathComponent:
            return "A path component was found that is of an unrecognized type."
        }
    }

    var details: String? {
        return nil
    }
}

extension InitializationError {
    var errorDescription: String? {
        return self.description
    }

    var description: String {
        return "\(self.title) – \(self.reason)"
    }

    var debugDescription: String {
        let basic = "\(self.title) – \(self.reason)"

        guard let details = self.details else {
            return basic
        }

        return "\(basic)\n\(details)"
    }
}
