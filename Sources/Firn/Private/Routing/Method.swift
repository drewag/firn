//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/20/20.
//

import NIOHTTP1

enum Method: Hashable {
    case get, post, put, delete
    case other(HTTPMethod)

    init(method: HTTPMethod) {
        switch method {
        case .GET:
            self = .get
        case .PUT:
            self = .put
        case .POST:
            self = .post
        case .DELETE:
            self = .delete
        default:
            self = .other(method)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get:
            return .GET
        case .put:
            return .PUT
        case .delete:
            return .DELETE
        case .post:
            return .POST
        case .other(let method):
            return method
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .get:
            0.hash(into: &hasher)
        case .put:
            1.hash(into: &hasher)
        case .post:
            2.hash(into: &hasher)
        case .delete:
            3.hash(into: &hasher)
        case .other:
            99999.hash(into: &hasher)
        }
    }
}

extension Method: Equatable {
    static func ==(lhs: Method, rhs: Method) -> Bool {
        switch lhs {
        case .get:
            switch rhs {
            case .get:
                return true
            default:
                return false
            }
        case .post:
            switch rhs {
            case .post:
                return true
            default:
                return false
            }
        case .delete:
            switch rhs {
            case .delete:
                return true
            default:
                return false
            }
        case .put:
            switch rhs {
            case .put:
                return true
            default:
                return false
            }
        case .other(let l):
            switch rhs {
            case .other(let r):
                return l == r
            default:
                return false
            }
        }
    }
}
