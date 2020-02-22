import NIO
import NIOHTTP1

public struct Response {
    var content: Any = EmptyResponseContent()
    var status: HTTPResponseStatus = .ok
    var headers = HTTPHeaders()

    func head(for request: Request?) -> HTTPResponseHead {
        var head = HTTPResponseHead(
            version: request?.head.version ?? HTTPVersion(major: 1, minor: 1),
            status: self.status,
            headers: self.headers
        )
        let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }

        if let request = request, !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
            // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers

            switch (request.head.isKeepAlive, request.head.version.major, request.head.version.minor) {
            case (true, 1, 0):
                // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
                head.headers.add(name: "Connection", value: "keep-alive")
            case (false, 1, let n) where n >= 1:
                // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
                head.headers.add(name: "Connection", value: "close")
            default:
                // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
                ()
            }
        }
        return head
    }
}
