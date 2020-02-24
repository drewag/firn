//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/21/20.
//

import Foundation

enum DecreeServiceWritingError: Error {
    case cannotWriteToFile
    case invalidName
    case invalidDomain
}

extension API {
    public func writeDecreeService(
        named serviceName: String,
        atDomain domain: String,
        to path: String
    ) throws {
        let invalidCharacters = CharacterSet.letters.inverted
        guard serviceName.rangeOfCharacter(from: invalidCharacters) == nil else {
            throw DecreeServiceWritingError.invalidName
        }

        guard URL(string: domain) != nil else {
            throw DecreeServiceWritingError.invalidDomain
        }

        guard FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            , let handle = Foundation.FileHandle(forWritingAtPath: path) else {
            throw DecreeServiceWritingError.cannotWriteToFile
        }

        handle.write("""
            //
            // \(serviceName)
            //
            // This file was automatically generated.
            //
            // DO NOT MODIFY
            //

            import Decree
            import Foundation

            public struct ExampleServiceError: AnyErrorResponse {
                let title: String
                let reason: String
                let details: String?

                public var message: String {
                    return "\\(title) – \\(reason)"
                }

                public var isInternal: Bool {
                    return false
                }
            }

            public struct \(serviceName): WebService {
                public typealias BasicResponse = NoBasicResponse
                public typealias ErrorResponse = \(serviceName)Error

                public static var shared = \(serviceName)()

                public var sessionOverride: Session?

                public let baseURL = URL(string: "\(domain)")!
            }

            // ----------------- Endpoints ----------------

            extension \(serviceName) {
            """)

            for (index, spec) in self.routeSpecs.enumerated() {
                let analyzer = RouteSpecAnalyzer(spec: spec, index: index)

                handle.write("""

                        public struct \(analyzer.endpointName): \(analyzer.endpointType) {
                            public typealias Service = \(serviceName)

                            public static let method = Method.\(analyzer.methodDefinition)
                            public static let authorizationRequirement = AuthorizationRequirement.\(analyzer.requiresAuthorization ? "required" : "none")

                    \(try analyzer.generateInputDefinition())
                    \(try analyzer.generateOutputDefinition())

                    \(analyzer.initMethod)

                    \(try analyzer.generatePathDefinition())
                        }

                    """)
            }

            handle.write("}")
    }
}

extension FileHandle {
    func write(_ string: String) {
        self.write(string.data(using: .utf8)!)
    }
}
