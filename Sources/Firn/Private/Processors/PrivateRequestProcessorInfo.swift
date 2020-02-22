import NIOHTTP1

public final class PrivateRequestProcessorInfo {
    let name: String?
    let method: HTTPMethod
    let lastPathComponent: PathComponent
    var requiresAuthentication: Bool = false
    var authenticationValidation = [(inout Request) throws -> ()]()

    init(name: String?, method: HTTPMethod, lastPathComponent: PathComponent) {
        self.name = name
        self.lastPathComponent = lastPathComponent
        self.method = method
    }
}
