import SwiftUI
import UIKit

/// SwiftUI wrapper around UIActivityViewController.
/// Pass `items` such as URLs (preferred for photos to preserve EXIF/metadata)
/// or raw data / UIImage.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return vc
    }

    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}
