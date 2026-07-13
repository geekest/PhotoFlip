import SwiftUI
import Photos

/// 视频卡片栈，对标 `CardStackView`：可见窗口仍为 3 张卡，
/// 但维护 4 个 `VideoPreviewLoader`（顶卡 + 预取后 3 个），
/// 每次前进时回收首个并预取再后一个，避免滑动时卡顿。
struct VideoCardStackView: View {
    @Bindable var viewModel: SwipeSessionViewModel

    /// 预取深度：顶卡 + 后 3 个。
    private static let poolSize = 4

    @State private var loaders: [VideoPreviewLoader] =
        (0..<VideoCardStackView.poolSize).map { _ in VideoPreviewLoader() }

    private let cardScales: [CGFloat] = [1.0, 0.94, 0.88]
    private let cardOffsets: [CGFloat] = [0, 12, 24]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visibleOffsets.reversed(), id: \.self) { offset in
                    let photoIndex = viewModel.currentIndex + offset
                    if let photo = viewModel.photos[safe: photoIndex] {
                        SwipeVideoCardView(
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
        .onDisappear {
            loaders.forEach { $0.cancel() }
        }
    }

    /// 可见卡片偏移（最多 3 张）。
    private var visibleOffsets: [Int] {
        (0..<3).filter { viewModel.photos[safe: viewModel.currentIndex + $0] != nil }
    }

    /// 前进一张：回收最前面的加载器，预取窗口最末（newIndex + poolSize-1）的视频。
    private func advanceForward(to newIndex: Int) {
        let outgoing = loaders.removeFirst()
        outgoing.cancel()
        loaders.append(outgoing)
        let prefetchIndex = newIndex + (Self.poolSize - 1)
        if let photo = viewModel.photos[safe: prefetchIndex] {
            loaders[Self.poolSize - 1].load(asset: photo.asset)
        }
        // 新顶卡的卡片视图被复用而非重建，故在此主动触发预览；
        // 若加载器尚未就绪则为空操作，由卡片的 isReady 变化兜底。
        loaders.first?.playPreview()
    }

    /// 初次加载或撤销：全部取消后从当前位置重新加载并预取。
    private func reloadAll(from index: Int) {
        for (i, loader) in loaders.enumerated() {
            loader.cancel()
            if let photo = viewModel.photos[safe: index + i] {
                loader.load(asset: photo.asset)
            }
        }
        loaders.first?.playPreview()
    }
}
