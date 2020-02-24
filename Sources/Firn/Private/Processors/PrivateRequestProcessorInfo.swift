import NIOHTTP1

public final class PrivateRequestProcessorInfo {
    let name: String?
    let method: HTTPMethod
    let lastPathComponent: PathComponent
    var requiresAuthentication: Bool = false
    var authenticationValidation = [(inout Request) throws -> ()]()

    var inputType: Any.Type
    var outputType: Any.Type

    init(
        name: String?,
        method: HTTPMethod,
        lastPathComponent: PathComponent,
        inputType: Any.Type
    ) {
        self.name = name
        self.lastPathComponent = lastPathComponent
        self.method = method
        self.inputType = inputType
        self.outputType = inputType
    }
}
