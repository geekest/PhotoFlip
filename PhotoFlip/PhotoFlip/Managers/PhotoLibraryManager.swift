import Photos
import UIKit

@Observable
final class PhotoLibraryManager: NSObject {
    var authorizationStatus: PHAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    /// Fetches photos sorted by creation date descending. limit=0 means no limit.
    func fetchAllPhotos(limit: Int = 0) async -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.fetchLimit = limit > 0 ? limit : 0

        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Fetches up to `limit` photos whose creationDate is on or before `date`,
    /// sorted by creation date descending (newest within the range first).
    func fetchPhotos(before date: Date, limit: Int) async -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType == %d AND creationDate <= %@",
            PHAssetMediaType.image.rawValue,
            date as NSDate
        )
        options.fetchLimit = limit > 0 ? limit : 0

        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Fetches `limit` photos chosen randomly from the entire library.
    /// When `excluding` is non-empty, photos whose localIdentifier is in that set are skipped.
    func fetchRandomPhotos(limit: Int, excluding: Set<String> = []) async -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: .image, options: options)
        let total = result.count
        guard total > 0 else { return [] }

        if excluding.isEmpty {
            let want = limit > 0 ? min(limit, total) : total
            var assets: [PHAsset] = []
            assets.reserveCapacity(want)
            if want == total {
                result.enumerateObjects { asset, _, _ in assets.append(asset) }
            } else {
                let pickedIndexes = randomIndexes(count: want, upperBound: total)
                result.enumerateObjects(at: pickedIndexes, options: []) { asset, _, _ in
                    assets.append(asset)
                }
            }
            assets.shuffle()
            return assets
        }

        // With exclusions: enumerate all assets, filter, shuffle, then limit.
        // PHAsset objects are lightweight metadata handles so enumerating the full
        // library is acceptable even for large collections.
        var candidates: [PHAsset] = []
        candidates.reserveCapacity(total)
        result.enumerateObjects { asset, _, _ in
            if !excluding.contains(asset.localIdentifier) {
                candidates.append(asset)
            }
        }
        candidates.shuffle()
        if limit > 0 && candidates.count > limit {
            return Array(candidates.prefix(limit))
        }
        return candidates
    }

    private func randomIndexes(count: Int, upperBound: Int) -> IndexSet {
        // Caller guarantees count < upperBound, so the rejection loop terminates quickly.
        var picked = Set<Int>()
        picked.reserveCapacity(count)
        while picked.count < count {
            picked.insert(Int.random(in: 0..<upperBound))
        }
        var set = IndexSet()
        for i in picked { set.insert(i) }
        return set
    }

    func deleteAssets(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }

    func setFavorite(asset: PHAsset, favorite: Bool) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = favorite
        }
    }
}

extension PhotoLibraryManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // External change notifications can be handled here if needed
    }
}
