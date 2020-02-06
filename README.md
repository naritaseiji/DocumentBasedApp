This is a sample project for a document-based app for iOS.

This is based on experience gained from the development of the personal database App [Firevault](https://apps.apple.com/us/app/firevault/id1439389822) for iOS.

The following is a translation of [an article posted to Qiita](https://qiita.com/gachalatte/items/b5a7839cb53eb34415d2).

# Document-Based App

The user selects the target, edits the content, saves it with a name. When developing such an app on iOS, a document-based app is the best choice.

If you adopt a document-based app, your app will have a variety of abilities.

* File operations with common user interface
  * Users can work with files with an interface similar to `Files.app`.

* File management by folders and tags
  * Users can organize files in the way that works best for them.

* File sharing with `iCloud Drive`
  * Teams can collaborate on files and make them read-only publicly.

* Support for external providers such as `Dropbox` and `Google Drive`
  * You can access the container of the external provider in the same way as the local directory. No framework or API calls are required.

* Seamless device-to-device synchronization
  * Changes to the file are immediately reflected in the user interface. This greatly enhances the user experience.


## File package
Before developing a document-based app, you need to design the format in which the files will be exported. If the document contains more than one content, the file package format is recommended.

The actual file package is just a directory, but iOS and macOS treat the file package as a single file. This ensures the integrity of the contained files. Files on the cloud can change while the app is running. If you read the moment when only some files are updated, it is inevitable that malfunction will occur. Ensuring consistency is a very important factor.

File packages are also very easy to handle. In the program, you can operate in the same way as a normal directory, and in the Mac Finder, you can also open it by `Right-click` > `Show package contents`.

Another feature of the file package is that files on the cloud can be transferred efficiently because only updated files can be sent and received.


## FileWrapper
Use `FileWrapper` to read and write file packages. You can read and write files directly without using `FileWrapper`, but you can enjoy the following benefits by using `FileWrapper`.

* Batch operation
  * Reading and writing of packages are performed at once. There is no need to read and write files individually. If you use `UIDocument`, there is no need to read or write.

* Write difference
  * Only changed files can be exported. This can be expected to improve performance during writing.

* Lazy loading
  * You can load the files in the package when you need them. This can improve read performance and save memory.

* File mapping
  * Files in the package can be opened as memory mapped files. This can improve read performance and save memory.


## UIDocument
`UIDocument` is a model that represents a document and a controller that reads and writes files. `UIDocument` has the following features, and allows you to develop document-based app with minimal code.

* Collaborative reading and writing
  * Files may be constantly updated by external processes. Therefore, cooperative read / write procedures using `NSFilePresenter` and `NSFileCoordinator` are required to read and write files. `UIDocument` uses these appropriately to read and write files cooperatively.

* Asynchronous read and write
  * Reading and writing files synchronously may cause the app to stop responding during that time. `UIDocument` uses a background queue to read and write files asynchronously.

* Monitor for updates
  * `UIDocument` monitors file updates and automatically reloads them. It also works safely if the file is moved to another location.

* Secure writing
  * `UIDocument` writes the file to a temporary directory, replacing the original file. If you crash while saving, you won't lose file integrity.

* Auto save
  * `UIDocument` saves the file automatically. Your changes will not be lost when you close the app.

* Notification of errors and conflicts
  * `UIDocument` keeps the status of errors and conflicts and notifies you when there is a change. The app can monitor this and take appropriate action.

* File access outside the sandbox
  * Document-based apps can open files outside the sandbox. The URL of the file outside the sandbox is called a `Security-scoped URL`, and you need to declare access before reading or writing. `UIDocument` automatically declares and releases access to `Security-scoped URL`.
    
## UIDocumentBrowserViewController
`UIDocumentBrowserViewController` is a class that displays a list of files included in the container and provides an interface to operate each file. It has almost the same function as `Files.app`.


# Sample project
`Xcode 11` provides a template for document-based app. Use this to create a project. The sample project uses SwiftUI.


## Project settings
The template implementation defines an image (public.image) file in the supported document format. Change this to a custom document.

Open `Project Settings` > `Info` and change the definition.


### Document Types

| Key | Value |
|:-|:-|
| Name | My Document |
| Types | net.gacha.mydoc |

Name specifies the text displayed on the screen as the file type.
For Types, define the UTI (Uniform Type Identifier) of the custom document. In the sample project, it is `net.gacha.mydoc`, but any unique string is acceptable.

#### Additional document type properties
| Key | Type | Value |
|:-|:-|:-|
| CFBundleTypeRole | String | Editor |
| LSHandlerRank | String | Owner |
| LSTypeIsPackage | Boolean | YES |

This part was not described in detail in the API document, and I could not understand enough to explain it properly. However, in this case, it has been confirmed that this setting works. For more information, check out `CFBundleDocumentTypes`.

### Exported UTIs

The template is initially empty, so add a row.

| Key | Value |
|:-|:-|
| Description | My Document |
| Identifier | net.gacha.mydoc |
| Conforms To | com.apple.package, public.composite-content |

Set UTI defined in Document Types for Identifier.
Conforms To represents the UTI to which the custom document fits. `com.apple.package` indicates a file package, and `public.composite-content` indicates that it consists of multiple contents.

#### Additional exported UTI properties

| Key | Type | Value |
|:-|:-|:-|
| UTTypeTagSpecification | Dictionary ||
| &nbsp;&nbsp;&nbsp;&nbsp;public.filename-extension | Array ||
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Item 0 | String | mydoc |

Public.filename-extension of UTTypeTagSpecification defines the file extension.


## Implementation
After setting up the project, implement the three classes provided in the template.

### Document
First, implement `Document`, a subclass of `UIDocument`.

```swift:Document.swift
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

```

For use in SwiftUI, Document conforms to `ObservableObject`, and each property has a `@Published` attribute to notify changes. This is to realize that the screen is updated when the property is changed. If you do not use SwiftUI, you can attach the `@objc` attribute and monitor with KVO. Also, what is optional considers the case where the file does not exist.

The properties `image` and `text` hold the contents of `image.png` and `text.txt`, respectively. If either property or file is changed, it will be reflected in the other.

Notable are `func contents (forType: String)-> Any` and `func load (fromContents: Any, ofType: String?) `. `UIDocument` calls these methods at appropriate times to read and write files. `contents` supports` Data` and `FileWrapper`, so you can read and write files simply by exchanging values ​​in these formats.

The extension part in the second half of the sample code is a helper for efficiently implementing the above implementation.


### DocumentBrowserViewController
`DocumentBrowserViewController` is a subclass of `UIDocumentBrowserViewController` and is the initial screen when the app starts.

In the initial state of the template, documents can be opened, but new documents cannot be created. Implement `func documentBrowser (_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL ?, UIDocumentBrowserViewController.ImportMode)-> Void)` to support new document creation.

```swift:DocumentBrowserViewController.swift
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("Document.mydoc")
        let document = Document(fileURL: temporaryURL)
        document.save(to: temporaryURL, for: .forCreating) { (success) in
            if success {
                importHandler(temporaryURL, .move)
            } else {
                importHandler(nil, .none)
            }
        }
    }
```

First, create a Document object and save it as a temporary file. When the save process is complete, call `importHandler`. Since you specify `.move` as ImportMode, there is no need to delete temporary files.

The file name of the temporary file is the file name of the document to be created. The extension should be the one defined in the project settings. This time, the file name is fixed as `Document.mydoc`, but if there is a file with the same name, there is no need to worry because the suffix is ​​automatically added like` Document 2.mydoc` .

In addition, since this method is designed asynchronously, it is possible to display a screen for entering a file name or a screen for selecting a template. Finally, make sure to call `importHandler`.


### DocumentView
Finally, implement DocumentView. `DocumentView` provides a user interface for displaying and updating `Document`.

```swift:DocumentView.swift
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

```

`DocumentView` is composed of the following four components.

* Text (document.localizedName)
  * Displays the document name.

* Group
  * View and edit the contents of document.image. Tap to display ImagePicker.

* TextView (text: text)
  * View and edit the contents of document.text.

* Button ("Done")
  * Close the document.

Basically this is all, but there are some things that need to be considered when implementing a UI that updates `UIDocument`. It is a change notification. `UIDocument` saves the document at the right time, but it needs to know that `UIDocument` itself has changed. When `document.hasUnsavedChanges` hits it and `hasUnsavedChanges` is `true`, the document is auto-saved. However, this property is readonly and cannot be set directly. `func updateChangeCount (_ change: UIDocument.ChangeKind)` is one way to update `hasUnsavedChanges`, but a better implementation is to use` UndoManager`.

`UndoManager` is a class that undoes and redoes operations. `UIDocument` has an instance of `UndoManager`, which can be used. By registering the process to return to the value before the change in `document.undoManager
when the property is changed, the app can get the ability of Undo / Redo and at the same time notify the UIDocument of the change. You.

The following is about SwiftUI, but in the sample code, in order to handle the value change, the following method is defined and the `Binding` object is dynamically passed to the View component. However, I am not so confident about this part. Please let me know if there is a better way.

```swift:DocumentView.swift
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
```

Once you have this done, let's run the project. (The iOS 13 simulator included with Xcode 11.3 has a problem that UIDocumentBrowserViewController does not work properly prior macOS Catalina.)

Create a file in `iCloud Drive` and make sure that the changes are reflected between devices. On the home screen, press and hold the App icon for a shortcut to select a file, or check that the app starts from `Files.app`.


#Task
Introducing the issues involved in developing a document-based app with real products.

## File number limit
Since `UIDocument` and `FileWrapper` operate on file packages at once, the performance decreases as the number of included files increases. If you have to give up using them, do all of your own tasks, such as monitoring changes with `NSFilePresenter`, cooperative reading and writing with `NSFileCoordinator`, asynchronous file access with background queue, and getting access to files outside the sandbox. is needed. In addition, when writing files directly without using a temporary directory, a design that takes into account that integrity is not guaranteed is required, and the difficulty of development rises at a stretch.

Before you start developing a document-based app, we recommend that you measure the performance by preparing the maximum number of dummy files that you expect.

## File package limitations
File packages are only valid for iOS and macOS. The moment you enter the outside world, it is treated as a normal directory. Therefore, you cannot save the file package to an external provider such as `Dropbox` or` Google Drive`. Also, if you send it by e-mail etc., the result will not be as expected. This will be a challenge when using file packages in actual products.

## File conflicts
If files are updated at the same time, the files may be in conflict. Conflicts need to be resolved, but there are many ways to do so. You can either overwrite everything with the latest changes or let the program decide and merge automatically. You can also give the user a choice.

## URL retention
You may want to remember the last file you opened for the next launch. In such cases, do not record the URL of the file directly. This is because users may rename or move files before opening the app the next time. Instead, create a bookmark from the URL and record it. Of course, the URL can change while the app is running. If you want to keep the URL in the object, you need to watch for changes.

## Read-only sharing
Files cannot be made read-only on iOS, but files on `iCloud Drive` are read-only and can be shared with other users. If a user modifies a read-only file, it will not be a big problem as it will be automatically restored to its original state, but it is possible to lock the edit button etc. so that the user can not change the document Would be better. Whether it is read-only can be determined by `URLResourceKey.ubiquitousSharedItemCurrentUserPermissionsKey`.

# Summary
Did you see that adopting a document-based app makes developing a rich and secure app very easy?

Various difficulties must be overcome before the product is actually completed, but nothing is as useful as a foundation.

In the era of cloud services, there may not be many opportunities to develop such a standalone app, but I think there is no loss in remembering the word document-based app alone.

Thank you for reading.
