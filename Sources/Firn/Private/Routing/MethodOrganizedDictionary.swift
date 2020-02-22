//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/20/20.
//

import NIOHTTP1

struct MethodOrganizedDictionary<Key: Hashable, Value> {
    var contents = [Method:[Key:Value]]()

    mutating func set(value: Value, for key: Key, and methods: [HTTPMethod]) {
        for method in methods {
            let method = Method(method: method)
            self.contents[method, default: [:]][key] = value
        }
    }

    func get(for key: Key, by method: HTTPMethod) -> Value? {
        let method = Method(method: method)
        return self.contents[method]?[key]
    }
}
