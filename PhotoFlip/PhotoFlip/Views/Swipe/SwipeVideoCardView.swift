import SwiftUI
import Photos

/// 视频整理卡片，对标 `SwipeCardView`：
/// 内联静音预览前 15 秒、左滑删除/右滑保留、爱心收藏、点击进入全屏播放。
struct SwipeVideoCardView: View {
    let photoItem: PhotoItem
    @Bindable var viewModel: SwipeSessionViewModel
    let isTopCard: Bool
    let loader: VideoPreviewLoader

    @State private var flyOffDirection: SwipeDecision?
    @State private var showDetail = false
    @State private var locationName: String?

    private let screenWidth = UIScreen.main.bounds.width
    private let dragThresholdX: CGFloat = 100

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)

            if loader.isReady, loader.player != nil {
                PlayerLayerView(player: loader.player)
                    .allowsHitTesting(false)
            } else {
                ProgressView()
            }

            // 视频角标，便于和照片区分
            Image(systemName: "play.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 6)
                .allowsHitTesting(false)

            bottomInfoStrip
                .allowsHitTesting(false)

            if isTopCard {
                DecisionOverlay(dragOffset: viewModel.dragOffset)

                Button {
                    viewModel.markFavorite(for: photoItem)
                } label: {
                    ZStack {
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 52, height: 52)
                            .shadow(color: .black.opacity(0.22), radius: 6, y: 3)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.pfOrange)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .cornerRadius(20)
        .shadow(color: isTopCard ? .black.opacity(0.28) : .black.opacity(0.14),
                radius: isTopCard ? 20 : 8, x: 0, y: isTopCard ? 12 : 4)
        .offset(isTopCard ? viewModel.dragOffset : .zero)
        .rotationEffect(
            isTopCard
                ? .degrees(Double(viewModel.dragOffset.width / screenWidth) * 15)
                : .zero
        )
        .gesture(isTopCard ? dragGesture : nil)
        .onTapGesture {
            guard isTopCard, loader.player != nil else { return }
            loader.prepareForDetail()
            showDetail = true
        }
        .onChange(of: flyOffDirection) { _, direction in
            guard let direction else { return }
            performFlyOff(to: direction)
        }
        .onChange(of: isTopCard) { _, nowTop in
            if nowTop { loader.playPreview() } else { loader.pause() }
        }
        .onChange(of: loader.isReady) { _, ready in
            if ready, isTopCard, !showDetail { loader.playPreview() }
        }
        .onAppear {
            if isTopCard, loader.isReady { loader.playPreview() }
        }
        .task(id: photoItem.id) {
            await loadLocation()
        }
        .sheet(isPresented: $showDetail, onDismiss: {
            // 退出详情：暂停并恢复静音，内联画面停在退出时那一帧。
            loader.pause()
            loader.player?.isMuted = true
        }) {
            if let player = loader.player {
                VideoDetailView(player: player)
            }
        }
    }

    @ViewBuilder
    private var bottomInfoStrip: some View {
        if photoItem.asset.creationDate != nil || photoItem.asset.location != nil
            || photoItem.asset.duration > 0 {
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .bottom,
                endPoint: .init(x: 0.5, y: 0.65)
            )
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    if photoItem.asset.duration > 0 {
                        Label(durationString(photoItem.asset.duration),
                              systemImage: "timer")
                            .font(.caption2)
                    }
                    if let date = photoItem.asset.creationDate {
                        Label(date.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                            .font(.caption2)
                    }
                    if let name = locationName {
                        Label(name, systemImage: "mappin")
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .foregroundStyle(.white)
                .padding(14)
            }
        }
    }

    private func durationString(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func loadLocation() async {
        guard let location = photoItem.asset.location else {
            locationName = nil
            return
        }
        let key = photoItem.id
        if let cached = LocationResolver.cached(for: key) {
            locationName = cached
            return
        }
        locationName = nil
        let resolved = await LocationResolver.resolve(location: location, assetID: key)
        if photoItem.id == key {
            locationName = resolved
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                viewModel.dragOffset = value.translation
            }
            .onEnded { value in
                let x = value.translation.width
                if x > dragThresholdX {
                    flyOffDirection = .keep
                } else if x < -dragThresholdX {
                    flyOffDirection = .delete
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.dragOffset = .zero
                    }
                }
            }
    }

    private func performFlyOff(to decision: SwipeDecision) {
        let targetOffset: CGSize
        switch decision {
        case .keep:
            targetOffset = CGSize(width: 700, height: viewModel.dragOffset.height)
        case .delete:
            targetOffset = CGSize(width: -700, height: viewModel.dragOffset.height)
        default:
            targetOffset = .zero
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.dragOffset = targetOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.processDecision(decision)
            viewModel.dragOffset = .zero
            flyOffDirection = nil
        }
    }
}
