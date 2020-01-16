//
//  DocumentView.swift
//  DocumentBasedApp
//
//  Created by Seiji Narita on 2020/01/16.
//  Copyright © 2020 GACHANET. All rights reserved.
//

import SwiftUI
import Combine

struct DocumentView: View {
    
    @ObservedObject var document: Document
    
    @State private var showImagePicker: Bool = false

    var dismiss: () -> Void

    var body: some View {

        return VStack(spacing: 30) {
            
            Text(document.localizedName)
                .font(.title)

            Group {
                if document.image == nil {
                    Button(action: {
                        self.showImagePicker = true
                    }) {
                        Image(systemName: "camera.on.rectangle").imageScale(.large).background(RoundedRectangle(cornerRadius: 6).foregroundColor(Color.secondary.opacity(0.1)))
                    }
                } else {
                    Image(uiImage: document.image!).resizable().aspectRatio(contentMode: .fit).frame(width: 240, height: 240)
                        .onTapGesture {
                            self.showImagePicker = true
                    }
                }
            }
                        
            TextView(text: bind(\.text))
                .frame(width: 240, height: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary, lineWidth: 1))
                        
            Button("Done", action: dismiss)
            
        }.sheet(isPresented: $showImagePicker) {
            ImagePicker(image: self.bind(\.image))
        }
    }

}

extension DocumentView {
    
    private func bind<Value>(_ keyPath: ReferenceWritableKeyPath<Document, Value>) -> Binding<Value> {
        let document = self.document
        return Binding<Value>(get: { () -> Value in
            return document[keyPath: keyPath]
        }, set: { (value) in
            let oldValue = document[keyPath: keyPath]
            document.undoManager.registerUndo(withTarget: document) { $0[keyPath: keyPath] = oldValue }
            document[keyPath: keyPath] = value
        })
    }
    
}


struct TextView: UIViewRepresentable {
    @Binding var text: String?
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String?
        var subscriptions: Set<AnyCancellable> = []

        init(text: Binding<String?>) {
            _text = text
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            text = textView.text.isEmpty ? nil : textView.text
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
    }
    
}


struct ImagePicker: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        @Binding var presentationMode: PresentationMode
        @Binding var image: UIImage?

        init(presentationMode: Binding<PresentationMode>, image: Binding<UIImage?>) {
            _presentationMode = presentationMode
            _image = image
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            presentationMode.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            presentationMode.dismiss()
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, image: $image)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {
    }

}
