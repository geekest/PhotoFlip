import Photos
import UIKit

@Observable
final class ImageLoader {
    var image: UIImage?
    private var requestID: PHImageRequestID?

    func load(asset: PHAsset, targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        requestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            if let image {
                self?.image = image
            }
        }
    }

    func cancel() {
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
            requestID = nil
        }
        image = nil
    }
}
