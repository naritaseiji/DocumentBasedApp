//
//  DocumentView.swift
//  DocumentBasedApp
//
//  Created by Seiji Narita on 2020/01/16.
//  Copyright © 2020 GACHANET. All rights reserved.
//

import SwiftUI

struct DocumentView: View {
    var document: UIDocument
    var dismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("File Name")
                    .foregroundColor(.secondary)

                Text(document.fileURL.lastPathComponent)
            }

            Button("Done", action: dismiss)
        }
    }
}
