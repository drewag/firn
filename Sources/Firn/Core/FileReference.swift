//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/27/20.
//

public struct FileReference {
    public let contentType: String
    public let localPath: String

    public init(contentType: String, localPath: String) {
        self.contentType = contentType
        self.localPath = localPath
    }
}
