import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct MediaPicker: UIViewControllerRepresentable {
    var onPicked: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let gifType = UTType(filenameExtension: "gif") ?? .image
        let controller = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .image,
                .movie,
                gifType,
                .audio,
                .plainText,
                .json,
                .pdf,
                .item
            ],
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
