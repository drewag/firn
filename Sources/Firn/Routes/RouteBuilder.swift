@_functionBuilder
public struct RouteBuilder {
    public static func buildBlock() -> ProcessorCollection {
        return EmptyProcessor()
    }

    public static func buildBlock(_ route: ProcessorCollection) -> ProcessorCollection {
        return MultiProcessor(specs: route.specs)
    }

    public static func buildBlock(_ routes: ProcessorCollection...) -> ProcessorCollection {
        return MultiProcessor(specs: routes.reduce([]) { current, next in
            return current + next.specs
        })
    }
}

public protocol ProcessorCollection {}

struct MultiProcessor: ProcessorCollection {
    let specs: [RouteSpec]
}

struct SingleProcessor: ProcessorCollection {
    let spec: RouteSpec
}

struct EmptyProcessor: ProcessorCollection {}

extension ProcessorCollection {
    var specs: [RouteSpec] {
        if let multi = self as? MultiProcessor {
            return multi.specs
        }
        else if let single = self as? SingleProcessor {
            return [single.spec]
        }
        else if let _ = self as? EmptyProcessor {
            return []
        }
        else if let processor = self as? AnyRequestProcessor {
            return [RouteSpec(
                path: [processor._routingHelper.lastPathComponent],
                processor: processor
            )]
        }
        else {
            fatalError("Unrecognized Collection")
        }
    }
}
