private struct UserFriendlyError: Encodable {
    let title: String
    let alertMessage: String
    let reason: String
    let details: String?
}

extension Response {
    static func create(from error: Error) -> Response {
        var response = Response()

        if let serveError = error as? ServeError {
            response.status = serveError.status

            response.content = UserFriendlyError(
                title: serveError.title,
                alertMessage: serveError.status == .internalServerError
                    ? "An internal error has occured with the description '\(serveError.reason)'. If it continues, please contact support including the description."
                    : serveError.reason,
                reason: serveError.reason,
                details: serveError.details
            )
        }
        else {
            response.status = .internalServerError

            response.content = UserFriendlyError(
                title: "Internal Server Error",
                alertMessage: "\(error)",
                reason: "Internal Server Error – \(error)",
                details: nil
            )
        }

        return response
    }
}
