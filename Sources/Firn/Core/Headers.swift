//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/21/20.
//

import NIOHTTP1

public struct Headers {
    let headers: HTTPHeaders

    init(headers: HTTPHeaders) {
        self.headers = headers
    }

    public subscript(name: String) -> [String] {
        return self.headers[canonicalForm: name].map({String($0)})
    }
}
