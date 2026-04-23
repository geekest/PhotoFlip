import SwiftUI
import Photos

struct CardStackView: View {
    @Bindable var viewModel: SwipeSessionViewModel

    @State private var loaders: [ImageLoader] = [ImageLoader(), ImageLoader(), ImageLoader()]

    private let cardScales: [CGFloat] = [1.0, 0.94, 0.88]
    private let cardOffsets: [CGFloat] = [0, 12, 24]

    private let targetSize: CGSize = {
        let w = UIScreen.main.bounds.width
        return CGSize(width: w * 2, height: w * 3)
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visibleOffsets.reversed(), id: \.self) { offset in
                    let photoIndex = viewModel.currentIndex + offset
                    if let photo = viewModel.photos[safe: photoIndex] {
                        SwipeCardView(
                            photoItem: photo,
                            viewModel: viewModel,
                            isTopCard: offset == 0,
                            loader: loaders[offset]
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(cardScales[offset])
                        .offset(y: cardOffsets[offset])
                        .zIndex(Double(3 - offset))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .onChange(of: viewModel.currentIndex) { oldIndex, newIndex in
            if newIndex > oldIndex {
                advanceForward(to: newIndex)
            } else {
                reloadAll(from: newIndex)
            }
        }
        .onAppear {
            reloadAll(from: viewModel.currentIndex)
        }
    }

    private var visibleOffsets: [Int] {
        (0..<3).filter { viewModel.photos[safe: viewModel.currentIndex + $0] != nil }
    }

    /// Called when swiping forward: recycle the outgoing loader, load the newly visible card.
    private func advanceForward(to newIndex: Int) {
        let outgoing = loaders.removeFirst()
        outgoing.cancel()
        loaders.append(outgoing)
        if let photo = viewModel.photos[safe: newIndex + 2] {
            loaders[2].load(asset: photo.asset, targetSize: targetSize)
        }
    }

    /// Called on undo or initial load: cancel all, reload from current index.
    private func reloadAll(from index: Int) {
        for (i, loader) in loaders.enumerated() {
            loader.cancel()
            if let photo = viewModel.photos[safe: index + i] {
                loader.load(asset: photo.asset, targetSize: targetSize)
            }
        }
    }
}

#Preview {
    let assets = PHAsset.fetchAssets(with: .image, options: nil)
    let count = min(assets.count, 3)
    let photos = (0..<count).map { PhotoItem(asset: assets[$0]) }
    let viewModel = SwipeSessionViewModel(photos: photos, libraryManager: PhotoLibraryManager())
    CardStackView(viewModel: viewModel)
        .aspectRatio(3/4, contentMode: .fit)
        .padding()
}
