//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/27/20.
//

public struct FileReference {
    public let contentType: String
    public let localPath: String

    public init(localPath: String, contentType: String? = nil) {
        self.localPath = localPath
        if let contentType = contentType {
            self.contentType = contentType
        }
        else {
            switch localPath.components(separatedBy: ".").last ?? "" {
            case "html", "htm":
                self.contentType = "text/html"
            case "xhtml":
                self.contentType = "application/xhtml+xml"
            case "xml":
                self.contentType = "text/xml"
            case "txt":
                self.contentType = "text/plain"
            case "js":
                self.contentType = "text/javascript"
            case "css":
                self.contentType = "text/css"
            case "json":
                self.contentType = "application/json"

            case "jpg", "jpeg":
                self.contentType = "image/jpeg"
            case "png":
                self.contentType = "image/png"
            case "pdf":
                self.contentType = "application/pdf"
            case "svg":
                self.contentType = "image/svg+xml"
            case "bmp":
                self.contentType = "image/bmp"
            case "gif":
                self.contentType = "image/gif"
            case "ico":
                self.contentType = "image/vnd.microsoft.icon"
            case "tif", "tiff":
                self.contentType = "image/tiff"

            case "otf":
                self.contentType = "font/otf"
            case "ttf":
                self.contentType = "font/ttf"

            default:
                self.contentType = "application/octet-stream"
            }
        }
    }
}
