//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/20/20.
//

import NIOHTTP1

struct MethodSet {
    var methods = [Method:Void]()
    
    mutating func append(_ method: HTTPMethod) {
        self.methods[Method(method: method)] = ()
    }

    var all: [HTTPMethod] {
        return self.methods.keys.map({$0.method})
    }
}
