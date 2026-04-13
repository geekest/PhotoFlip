import Photos

struct PhotoItem: Identifiable {
    let asset: PHAsset
    var decision: SwipeDecision = .undecided
    var wasDeletedFromLibrary: Bool = false

    var id: String { asset.localIdentifier }
}
