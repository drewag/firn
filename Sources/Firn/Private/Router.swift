import NIOHTTP1

struct Router {
    indirect enum Handler {
        case router(Router, MethodSet)
        case route(AnyRequestProcessor)
    }

    var staticChildren = MethodOrganizedDictionary<String,Handler>()
    var variableChildren = MethodOrganizedDictionary<Var,Handler>()
    var hasSocketRoutes: Bool = false

    mutating func append(_ collection: ProcessorCollection) throws {
        for spec in collection.specs {
            try self.append(spec.processor, at: spec.path)
        }
    }

    func processor(for path: String, by method: HTTPMethod) -> (AnyRequestProcessor, PathParams)? {
        return self.processor(for: path.split(separator: "/"), by: method, params: PathParams())
    }
}

private extension Router {
    mutating func append(_ processor: AnyRequestProcessor, at path: [PathComponent]) throws {
        if processor is WebSocketProcessor {
            self.hasSocketRoutes = true
        }
        let method = processor._routingHelper.method
        switch path.count {
        case 0:
            guard self.staticChildren.get(for: "", by: method) == nil else {
                throw InitializationError.routeConflict
            }
            self.staticChildren.set(value: .route(processor), for: "", and: [method])
        case 1:
            let component = path.last!
            if let string = component as? String {
                guard self.staticChildren.get(for: string, by: method) == nil else {
                    throw InitializationError.routeConflict
                }
                self.staticChildren.set(value: .route(processor), for: string, and: [method])
            }
            else if let variable = component as? Var {
                guard self.variableChildren.get(for: variable, by: method) == nil else {
                    throw InitializationError.routeConflict
                }
                self.variableChildren.set(value: .route(processor), for: variable, and: [method])
            }
            else {
                throw InitializationError.unrecognizedPathComponent
            }
        default:
            var path = path
            let component = path.removeFirst()
            let handler: Handler

            func update(_ handler: Handler?) throws -> (Handler, MethodSet) {
                var router: Router
                var methods = MethodSet()
                switch handler ?? .router(Router(), MethodSet()) {
                case let .route(route):
                    router = Router()
                    methods.append(route._routingHelper.method)
                    try router.append(route, at: [])
                case let .router(existingRouter, existingMethods):
                    router = existingRouter
                    methods = existingMethods
                }
                methods.append(processor._routingHelper.method)
                try router.append(processor, at: path)
                return (.router(router, methods), methods)
            }

            if let string = component as? String {
                let (handler, methods) = try update(self.staticChildren.get(for: string, by: method))
                self.staticChildren.set(value: handler, for: string, and: methods.all)
            }
            else if let variable = component as? Var {
                let (handler, methods) = try update(self.variableChildren.get(for: variable, by: method))
                self.variableChildren.set(value: handler, for: variable, and: methods.all)
            }
            else {
                throw InitializationError.unrecognizedPathComponent
            }
        }
    }

    func processor(for path: [String.SubSequence], by method: HTTPMethod, params: PathParams) -> (AnyRequestProcessor, PathParams)? {
        var params = params
        var path = path
        let component: String
        switch path.count {
        case 0:
            component = ""
        default:
            component = String(path.removeFirst())
        }

        let handler: Handler?
        if let staticHandler = self.staticChildren.get(for: component, by: method) {
            handler = staticHandler
        }
        else if let int = Int(component), let intHandler = self.variableChildren.get(for: .int, by: method) {
            params.append(int)
            handler = intHandler
        }
        else if let stringHandler = self.variableChildren.get(for: .string, by: method) {
            params.append(component)
            handler = stringHandler
        }
        else {
            handler = nil
        }

        guard let finalHandler = handler else {
            return nil
        }

        switch finalHandler {
        case .route(let processor):
            guard path.isEmpty else {
                return nil
            }
            return (processor, params)
        case .router(let router, _):
            return router.processor(for: path, by: method, params: params)
        }
    }
}
