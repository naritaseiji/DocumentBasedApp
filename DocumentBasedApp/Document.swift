//
//  Document.swift
//  DocumentBasedApp
//
//  Created by Seiji Narita on 2020/01/16.
//  Copyright © 2020 GACHANET. All rights reserved.
//

import UIKit

class Document: UIDocument, ObservableObject {

    @Published var image: UIImage?
    @Published var text: String?

    override func contents(forType typeName: String) throws -> Any {
        return FileWrapper(directoryWithFileWrappers: Dictionary(uniqueKeysWithValues: FileID.allCases.compactMap(fileWrapper(for:)).map({ ($0.preferredFilename!, $0) })))
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapper = contents as? FileWrapper, fileWrapper.isDirectory else { return }
        FileID.allCases.compactMap({ (fileID) -> (FileID, Data?)? in
            guard let child = fileWrapper.fileWrappers?[filename(for: fileID)] else { return nil }
            return (fileID, child.regularFileContents)
        }).forEach({ (fileID, data) in
            setData(data, for: fileID)
        })
    }
    
}


extension Document {

    private enum FileID: CaseIterable {
        case image
        case text
    }

    private func filename(for fileID: FileID) -> String {
        switch fileID {
        case .image:
            return "image.png"
        case .text:
            return "text.txt"
        }
    }
    
    private func data(for fileID: FileID) -> Data? {
        switch fileID {
        case .image:
            return image?.pngData()
        case .text:
            return text?.data(using: .utf8)
        }
    }
    
    private func setData(_ data: Data?, for fileID: FileID) {
        switch fileID {
        case .image:
            image = {
                guard let data = data else { return nil }
                return UIImage(data: data)
            }()
        case .text:
            text = {
                guard let data = data else { return nil }
                return String(data: data, encoding: .utf8)!
            }()
        }
    }

    private func fileWrapper(for fileID: FileID) -> FileWrapper? {
        guard let data = data(for: fileID) else { return nil }
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = filename(for: fileID)
        return fileWrapper
    }

}
