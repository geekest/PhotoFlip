import Photos

struct PhotoItem: Identifiable, Equatable {
    let asset: PHAsset
    var decision: SwipeDecision = .undecided
    var wasDeletedFromLibrary: Bool = false

    var id: String { asset.localIdentifier }

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.decision == rhs.decision &&
        lhs.wasDeletedFromLibrary == rhs.wasDeletedFromLibrary
    }
}
