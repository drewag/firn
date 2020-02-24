import Foundation
import NIOHTTP1

struct RouteSpecAnalyzer {
    let spec: RouteSpec
    let index: Int

    init(spec: RouteSpec, index: Int) {
        self.spec = spec
        self.index = index
    }

    var endpointName: String {
        if var custom = spec.processor._routingHelper.name {
            let invalidCharacters = CharacterSet.letters.inverted
            if custom.rangeOfCharacter(from: invalidCharacters) != nil {
                custom = "InvalidlyNamedEndpoint\(index + 1)"
            }
            return custom
        }

        return "Endpoint\(index + 1)"
    }

    var input: Any {
        
    }

    var hasInput: Bool {
        return false
    }

    var output: Any.Type {
        return self.spec.processor._routingHelper.outputType
    }

    var hasOutput: Bool {
        if self.output == String.self {
            return true
        }
        return false
    }

    var method: HTTPMethod {
        return spec.processor._routingHelper.method
    }

    var requiresAuthorization: Bool {
        return self.spec.processor._routingHelper.requiresAuthentication
    }

    var pathComponents: [PathComponent] {
        return spec.path
    }

    var variableComponents: [Var] {
        return self.pathComponents.compactMap({ $0 as? Var})
    }

    func generatePath() throws -> String {
        return try "/" + self.pathComponents.map({ component in
            if let component = component as? String {
                return component
            }
            else if let component = component as? Var {
                switch component.kind {
                case .int:
                    return "<Int>"
                case .string:
                    return "<String>"
                }
            }
            else {
                throw InitializationError.unrecognizedPathComponent
            }
        }).joined(separator: "/")
    }
}

extension RouteSpecAnalyzer {
    var endpointType: String {
        switch (self.hasInput, self.hasOutput) {
        case (true, true):
            return "InOutEndpoint"
        case (false, true):
            return "OutEndpoint"
        case (true, false):
            return "InEndpoint"
        case (false, false):
            return "EmptyEndpoint"
        }
    }

    func generatePathDefinition() throws -> String {
        if self.variableComponents.isEmpty {
            return "        public let path = \"\(try self.generatePath())\""
        }
        else {
            return """
                        public var path: String {
                            return \"\(try self.generateVariablePath())\"
                        }
                """
        }
    }

    func generateDefinition(for type: Any.Type, named: String) throws -> String {
        return "        public typealias \(named) = String"
    }

    func generateOutputDefinition() throws -> String {
        guard self.hasOutput else {
            return ""
        }
        return try self.generateDefinition(for: self.output, named: "Output")
    }

    func generateInputDefinition() throws -> String {
        guard self.hasInput else {
            return ""
        }
        return try self.generateDefinition(for: self.output, named: "Input")
    }

    func generateVariablePath() throws -> String {
        var index = 0
        return try "/" + self.pathComponents.map({ comp in
            index += 1
            if let comp = comp as? String {
                return "\(comp)"
            }
            else if let comp = comp as? Var {
                let name = comp.name ?? "component\(index)"
                return "\\(\(name))"
            }
            else {
                throw InitializationError.unrecognizedPathComponent
            }
        }).joined(separator: "/")
    }

    var initArguments: String {
        var index = 0
        return self.variableComponents.map({ comp in
            index += 1
            let name = comp.name ?? "component\(index)"
            switch comp.kind {
            case .int:
                return "\(name): Int"
            case .string:
                return "\(name): String"
            }
        }).joined(separator: ", ")
    }

    var attributes: String {
        var index = 0
        return self.variableComponents.map({ comp in
            index += 1
            let name = comp.name ?? "component\(index)"
            switch comp.kind {
            case .int:
                return "        let \(name): Int"
            case .string:
                return "        let \(name): String"
            }
        }).joined(separator: "\n")
    }

    var setters: String {
        var index = 0
        return self.variableComponents.map({ comp in
            index += 1
            let name = comp.name ?? "component\(index)"
            return "            self.\(name) = \(name)"
        }).joined(separator: "\n")
    }

    var initMethod: String {
        if self.variableComponents.isEmpty {
            return "        public init() {}"
        }
        else {
            return """
                \(self.attributes)

                        public init(\(self.initArguments)) {
                \(self.setters)
                        }
                """
        }
    }

    var methodDefinition: String {
        return "\(self.method)".lowercased()
    }
}
