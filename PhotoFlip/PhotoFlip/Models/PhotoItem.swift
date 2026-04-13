import Photos

struct PhotoItem: Identifiable {
    let asset: PHAsset
    var decision: SwipeDecision = .undecided

    var id: String { asset.localIdentifier }
}
