//
//  File.swift
//  
//
//  Created by Andrew Wagner on 1/4/21.
//

public enum SSL {
    case none
    case fileSystem(keyPath: String, certPaths: [String])
}
