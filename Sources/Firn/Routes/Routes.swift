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
