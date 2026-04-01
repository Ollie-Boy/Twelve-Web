import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct MediaPicker: UIViewControllerRepresentable {
    enum Kind {
        case photo
        case video
        case audio
    }

    var kind: Kind
    var onPicked: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType]
        switch kind {
        case .photo:
            let gifType = UTType(filenameExtension: "gif") ?? .image
            types = [.image, gifType]
        case .video:
            types = [.movie, .video]
        case .audio:
            types = [.audio]
        }
        let controller = UIDocumentPickerViewController(
            forOpeningContentTypes: types,
            asCopy: true
        )
        controller.allowsMultipleSelection = true
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

extension MediaPicker {
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPicked: ([URL]) -> Void

        init(onPicked: @escaping ([URL]) -> Void) {
            self.onPicked = onPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPicked(urls)
        }
    }
}
