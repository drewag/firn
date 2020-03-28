import Foundation

public func GET(named name: String? = nil, _ component: PathComponent = "") -> RequestProcessor<Void, EmptyResponseContent>  {
    let helper = PrivateRequestProcessorInfo(name: name, method: .GET, lastPathComponent: component)
    return RequestProcessor(helper: helper, before: nil)
}

public func POST(named name: String? = nil, _ component: PathComponent = "") -> RequestProcessor<Void, DataBuffer>  {
    let helper = PrivateRequestProcessorInfo(name: name, method: .POST, lastPathComponent: component)
    return RequestProcessor(helper: helper, before: nil, newStatus: .created)
}

public func PUT(named name: String? = nil, _ component: PathComponent = "") -> RequestProcessor<Void, DataBuffer>  {
    let helper = PrivateRequestProcessorInfo(name: name, method: .PUT, lastPathComponent: component)
    return RequestProcessor(helper: helper, before: nil)
}

public func DELETE(named name: String? = nil, _ component: PathComponent = "") -> RequestProcessor<Void, EmptyResponseContent>  {
    let helper = PrivateRequestProcessorInfo(name: name, method: .DELETE, lastPathComponent: component)
    return RequestProcessor(helper: helper, before: nil, process: nil)
}

public func Group(_ component: PathComponent, @RouteBuilder _ build: () -> ProcessorCollection) -> ProcessorCollection {
    return MultiProcessor(specs: build().specs.map { spec in
        var spec = spec
        spec.path.insert(component, at: 0)
        return spec
    })
}

public func Auth<User: AnyUser>(_ type: User.Type, verify: ((User) throws -> Bool)? = nil, @RouteBuilder _ build: () -> ProcessorCollection) -> ProcessorCollection {
    return MultiProcessor(specs: build().specs.map { spec in
        spec.processor._routingHelper.requiresAuthentication = true
        spec.processor._routingHelper.authenticationValidation.append({ request in
            try request.authenticate(User.self, validate: verify)
        })
        return spec
    })
}

public func Socket(named name: String? = nil, _ component: PathComponent = "", getHandler: @escaping (Request) throws -> SocketConnectionHandler?) -> WebSocketProcessor {
    let helper = PrivateRequestProcessorInfo(name: name, method: .GET, lastPathComponent: component)
    return WebSocketProcessor(helper: helper, getHandler: getHandler)
}

public func StaticDirectory(root: String) -> ProcessorCollection {
    return GET(named: nil, Var.path)
        .toFile({ request in
            let root = URL(fileURLWithPath: root)
            let path = root.appendingPathComponent(try request.pathParams.capturePath().joined(separator: "/"))

            func reference(forFilePath path: URL, automaticIndex: Bool) throws -> FileReference {
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: path.relativePath, isDirectory: &isDirectory) else {
                    throw ServeError.routeNotFound
                }

                guard !isDirectory.boolValue else {
                    if automaticIndex {
                        throw ServeError.routeNotFound
                    }
                    else {
                        return try reference(forFilePath: path.appendingPathComponent("index.html"), automaticIndex: true)
                    }
                }
                return FileReference(localPath: path.relativePath)
            }

            return try reference(forFilePath: path, automaticIndex: false)
        })
}
