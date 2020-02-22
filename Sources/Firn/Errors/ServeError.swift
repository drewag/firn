import Foundation
import NIOHTTP1

public enum ServeError: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    case internalServerError(reason: String, details: String?)
    case badRequest(title: String, reason: String, details: String?)

    case missingRequest
    case routeNotFound

    case invalidRequestBodyString
    case invalidRequestBodyObject(decodingError: Error)

    case invalidResponseBody(type: String)

    case authenticatorNotConfigured(type: String)
    case unauthorized

    case databaseNotConfigured

    var status: HTTPResponseStatus {
        switch self {
        case .internalServerError, .missingRequest, .databaseNotConfigured,
             .invalidResponseBody, .authenticatorNotConfigured:
            return .internalServerError
        case .routeNotFound:
            return .notFound
        case .badRequest, .invalidRequestBodyString, .invalidRequestBodyObject:
            return .badRequest
        case .unauthorized:
            return .unauthorized
        }
    }

    var title: String {
        switch self {
        case .internalServerError, .missingRequest, .databaseNotConfigured,
             .invalidResponseBody, .authenticatorNotConfigured:
            return "Internal Server Error"
        case .routeNotFound:
            return "Not Found"
        case .invalidRequestBodyString, .invalidRequestBodyObject:
            return "Invalid Request"
        case .unauthorized:
            return "Unauthorized"
        case .badRequest(let title, _, _):
            return title
        }
    }

    var reason: String {
        switch self {
        case .badRequest(_, let reason, _):
            return reason
        case .internalServerError(let reason, _):
            return reason
        case .missingRequest:
            return "The request could not be found."
        case .routeNotFound:
            return "This endpoint could not be found."
        case .invalidRequestBodyString:
            return "This endpoint requires a string body."
        case .invalidRequestBodyObject:
            return "Invalid json object."
        case .unauthorized:
            return "This endpoint requires you to be authorized."
        case .databaseNotConfigured:
            return "The database connection has not been configured."
        case .invalidResponseBody(let type):
            return "The response body is of an invalid type `\(type)`."
        case .authenticatorNotConfigured(let type):
            return "An authenticator has not been configured for '\(type)'."
        }
    }

    var details: String? {
        switch self {
        case .badRequest(_, _, let details):
            return details
        case .internalServerError(_, let details):
            return details
        case .missingRequest, .routeNotFound, .invalidRequestBodyString,
             .unauthorized, .databaseNotConfigured, .invalidResponseBody,
             .authenticatorNotConfigured:
            return nil
        case .invalidRequestBodyObject(let decodingError):
            return "Decoding Error: \(decodingError)"
        }
    }
}

extension ServeError {
    public var errorDescription: String? {
        return self.description
    }

    public var description: String {
        return "\(self.title) – \(self.reason)"
    }

    public var debugDescription: String {
        let basic = "\(self.title) – \(self.reason)"

        guard let details = self.details else {
            return basic
        }

        return "\(basic)\n\(details)"
    }
}
