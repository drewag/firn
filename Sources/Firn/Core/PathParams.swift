//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/20/20.
//

public struct PathParams {
    var ints = [Int]()
    var strings = [String]()

    var isEmpty: Bool {
        return self.ints.isEmpty && self.strings.isEmpty
    }

    mutating func append(_ int: Int) {
        self.ints.append(int)
    }

    mutating func append(_ string: String) {
        self.strings.append(string)
    }

    public func int(at index: Int) throws -> Int {
        guard index >= 0 && index < self.ints.count else {
            throw ServeError.internalServerError(
                reason: "Attempted to access a non-existent path parameter.",
                details: "Integer at \(index)."
            )
        }
        return self.ints[index]
    }

    public func string(at index: Int) throws -> String {
        guard index >= 0 && index < self.strings.count else {
            throw ServeError.internalServerError(
                reason: "Attempted to access a non-existent path parameter.",
                details: "String at \(index)."
            )
        }
        return self.strings[index]
    }
}
