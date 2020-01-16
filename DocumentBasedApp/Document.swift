//
//  Document.swift
//  DocumentBasedApp
//
//  Created by Seiji Narita on 2020/01/16.
//  Copyright © 2020 GACHANET. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

